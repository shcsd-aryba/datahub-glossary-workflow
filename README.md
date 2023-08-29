# datahub-glossary-workflow
Datahub glossary ingestion workflow. It uses the Excel spreadsheet as a template where user can enter their glossary nodes and terms, then the Python and bash script works together to ingest the glossary into datahub. It can be added to the cicd pipeline with few additional assertions in the cicd to make sure the workflow did not fail.

Workflow
Step 1: Let the user enter the terms and nodes in the spreadsheet. Also read the notes tab on spreadsheet for details, List tab contains the list of the nodes and subnodes used on the main Glossary sheet. Fill that out per your organization structure.
Step 2: Python script is used to translate the excel file into yaml file to ingest into datahub. Please nopte, if you change the headers on spreadsheet, make similar modification with in python script to synch the changes.
Step 3: Use the bash file to load streamline the process, It is an optional add on, that way you can add this script on your cicd pipeline and add some assertions to makesure everything run smooth.