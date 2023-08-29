####################################################################################################
########## Author: Basanta Aryal  ############################## Created Date: 07/31/2023 ##########
####################################################################################################
########## Last Modified by: Basanta Aryal      ########## Last Modified Date: 07/31/2023 ##########
####################################################################################################
##    This is a python script that converts the given spreadsheet (xlsx) file to Yaml format.     ##
## The desired columns are hardcoded, if the changes are needed code can be modified respectively ##
####################################################################################################
##Pre-Req1: Pandas for python3.5+:'pip3 install pandas' on Linux, 'pip install pandas' on Windows ##
##Pre-Req2: Openpyxl for python3.5+:'pip3 install openpyxl' on Lin, 'pip install openpyxl' Windows##
####################################################################################################

import pandas as pd
import sys
import json
import uuid
import yaml
import openpyxl

def convert_to_yaml(df):
    # Building the python dictionary with static header required for the Datahub Glossary ingestion
    data = {        
        "version": 1,
        "source": "DataHub",
        "owners": {
            "users": ["datahubadmin"]
        },
        "nodes": []
    }

    nodes = {}
    sub_nodes = {}
    
    # Iterating through excel rows  to get the glossary node(groups), subnode(sub groups) and terms
    for index, row in df.iterrows():
        
        #Excel Row Headers
        # 'term group' is teh 'glossary term group root node'; 
        # 'term sub group' is 'glossary term sub group node'; 
        # 'term name' is a 'glossary term' which either fall under 'glossary term group root node' or under 'glossary term sub group node'
        term_group_name = row['Root Folder Name']
        term_group_description = row['Root Folder Description']
        term_group_owner_user = row['Root Folder Owner-Users']

        term_sub_group_name = row['Folder Name']
        term_sub_group_description = row['Folder Description']
        term_sub_group_owner_user = row['Folder Owner-Users']

        term_name = row['Term Name']
        term_description = row['Term Description']
        term_owner_user = row['Term Owner-Users']
        source_reference = row['Source Reference']
        source_url_link = row['Source URL']
        inherit_terms = row['Inherit Terms']
        contain_terms = row['Contain Terms']
        terms_custom_properties = row['Custom Properties']
        terms_domain = row['Domain']

        # Skip the excel row if the term name is null
        if not pd.notnull(term_name) and not pd.notnull(term_group_name):
            continue
        
        # Build a node only if the node already does not exist in the dictionary, Note there should be a value for Node always and ever. No Node name just send a error message, must provide node name
        if pd.notnull(term_group_name):
            if term_group_name not in nodes:
                node_id = str(uuid.uuid4())
                node_data = {
                    "name": term_group_name,
                    "description": term_group_description if pd.notnull(term_group_description) else term_group_name,
                    "id": node_id,
                    "owners": {
                        "users": term_group_owner_user.replace('; ',';').split(';') if pd.notnull(term_group_owner_user) else []
                    },
                    "nodes": [],
                    "terms": []
                }
                nodes[term_group_name] = node_data
                data["nodes"].append(node_data)
        else: 
            error = {        
                "Error message": "You must provide a node name, please look at the following line number and row identifiers and correct then re try to convert.",
                "line": index,
                "Key row identifiers":  str(row)
            }
            return yaml.dump(error, default_flow_style=False,sort_keys=False)
        
        # Build a sub node object only if the sub node already does not exist in the dictionary and only if Sub node present
        if pd.notnull(term_sub_group_name):
            if term_sub_group_name not in sub_nodes:
                sub_node_id = str(uuid.uuid4())
                sub_node_data = {
                    "name": term_sub_group_name,
                    "description": term_sub_group_description if pd.notnull(term_sub_group_description) else term_sub_group_name,
                    "id": sub_node_id,
                    "owners": {
                        "users": term_sub_group_owner_user.replace('; ',';').split(';') if pd.notnull(term_sub_group_owner_user) else []
                    },
                    "terms": []
                }
                sub_nodes[term_sub_group_name] = sub_node_data
                node_data["nodes"].append(sub_node_data)
        
        #print(terms_custom_properties)
        #Build a term object 
        if pd.notnull(term_name):
            term_data = {
                "name": term_name,
                "description": term_description if pd.notnull(term_description) else term_name,
                "id": str(uuid.uuid4()),
                "owners": {
                    "users": term_owner_user.replace('; ',';').split(';') if pd.notnull(term_owner_user) else []
                },
                "term_source": "EXTERNAL",
                "source_ref": source_reference if pd.notnull(source_reference) else None,
                "source_url": source_url_link if pd.notnull(source_url_link) else None,
                "inherits": inherit_terms.replace('; ',';').split(';') if pd.notnull(inherit_terms) else [],
                "contains": contain_terms.replace('; ',';').split(';') if pd.notnull(contain_terms) else [],
                "custom_properties": dict(s.replace(': ',':').split(':') for s in terms_custom_properties.replace('; ',';').split(';'))  if pd.notnull(terms_custom_properties) else [],
                "domain": terms_domain if pd.notnull(terms_domain) else None
            }
        
            #Append the terms into sub node if subnode present otherwise append it to root node, note root node must be present at all time
            if pd.notnull(term_sub_group_name):
                sub_node_data["terms"].append(term_data) 
            else:
                node_data["terms"].append(term_data)
            
    #print(data)
    #return data
    #print(yaml.dump(data, default_flow_style=False,sort_keys=False))
    return yaml.dump(data, default_flow_style=False,sort_keys=False)

def main():
    # Replace 'glossary.xlsx' with the actual path to your spreadsheet file
    in_file = sys.argv[1]
    out_file = sys.argv[2]
    df = pd.read_excel(in_file, 'Glossary', header = 1)
    yaml_output = convert_to_yaml(df)
    
    # Replace 'glossary.yaml' with the actual path to your desired output file
    with open(out_file, 'w') as file:
        file.write(yaml_output)

if __name__ == "__main__":
    main()
