import requests
import json
import os
from dotenv import load_dotenv
from google.cloud import bigquery


os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = "/Users/narbeh/.config/gcloud/application_default_credentials.json"


load_dotenv(".env")
sentineloneapiurl=os.getenv("sentineloneapiurl")
Sentinelone_ApiToken = os.getenv("Sentinelone_ApiToken")
project=os.getenv("project")
dataset_id = os.getenv("dataset_id")
accountIds=os.getenv("accountIds")

def GetEndpoints():
    api="/web/api/v2.1/export/agents-light"
    headers={
        "Authorization":"ApiToken "+Sentinelone_ApiToken,
        "Accept":"file/csv"
    }
    
    response= requests.get(url=sentineloneapiurl+api,headers=headers)
    return response.text

def GetInventoryApplications(appName,appVendorName):
    
    api="/web/api/v2.1/application-management/inventory/endpoints/export/csv?applicationName="+appName+"&applicationVendor="+appVendorName+"&accountIds="+accountIds
    headers={
        "Authorization":"ApiToken "+Sentinelone_ApiToken,
        "Accept":"application/json, text/plain"
    }
    
    response= requests.get(url=sentineloneapiurl+api,headers=headers)
    return response.text

def GetCSVheaders(filename):
    import csv
    
    # opening the csv file by specifying
    # the location
    # with the variable name as csv_file
    with open(filename) as csv_file:
    
        # creating an object of csv reader
        # with the delimiter as ,
        csv_reader = csv.reader(csv_file, delimiter = ',')
    
        # list to store the names of columns
        list_of_column_names = []
    
        # loop to iterate through the rows of csv
        for row in csv_reader:
    
            # adding the first row
            list_of_column_names.append(row)
    
            # breaking the loop after the
            # first iteration itself
            break
    return list_of_column_names
    
def CreateBigQueryTable(filename, project, dataset_id, table_id,filetype):

    # Initialize a BigQuery client
    client = bigquery.Client(project)

    # Define your BigQuery dataset and table
    
    if filetype=="csv":
        # Configure the load job for CSV
        schema=[]
        list_of_column_names=GetCSVheaders(filename)
        for i in  list_of_column_names[0]:
            schema = schema+[bigquery.SchemaField(i, "STRING", mode="Nullable")]



        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,  # Adjust if your CSV has a header
            #autodetect=True,      # Auto-detect schema
            schema=schema
        )
    if filetype=="json":
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            autodetect=True,      # Auto-detect schema
        )

    # Load the CSV data into BigQuery
    with open(filename, "rb") as source_file:
        job = client.load_table_from_file(source_file, f"{dataset_id}.{table_id}", job_config=job_config)

    job.result()  # Wait for the job to complete

    return (f"Loaded {job.output_rows} rows into {dataset_id}:{table_id}.")

def DeteleBigQueryTable(project, dataset_id, table_id):
    ##delete table
    # Initialize a BigQuery client
    client = bigquery.Client(project)
    client.delete_table(f"{dataset_id}.{table_id}", not_found_ok=True)  # Make an API request.
    return ("Deleted table '{}'.".format(f"{dataset_id}.{table_id}"))


### main script

### first delete all tables

DeteleBigQueryTable(project, dataset_id, "JavaApps")
DeteleBigQueryTable(project, dataset_id, "SentinelOneData")
DeteleBigQueryTable(project, dataset_id, "JamfComputers")
DeteleBigQueryTable(project, dataset_id, "IntuneComputers")

## Get Java Data
javaapps="""[
     {
        "appName":"Java 6",
        "appVendorName":"Oracle" 
    },
    {
        "appName":"Java 7",
        "appVendorName":"Oracle" 
    },
    {
        "appName":"Java 8",
        "appVendorName":"Oracle America, Inc." 
    },
    {
        "appName":"Java 8",
        "appVendorName":"Oracle Corporation" 
    },
    {
        "appName":"java8u361",
        "appVendorName":"Installer" 
    },
    {
        "appName":"Java_8_Update_291",
        "appVendorName":"Oracle America, Inc." 
    },
    {
        "appName":"Java_8_Update_301",
        "appVendorName":"Oracle America, Inc." 
    },
    {
        "appName":"Java SE Development Kit",
        "appVendorName":"Oracle Corporation" 
    }
    
]"""
responsejson = json.loads(javaapps)
totalcsv=""
for k in responsejson:
    # data=data+GetInventoryApplications(k["appName"],k["appVendorName"])
    data=""
    data=GetInventoryApplications(k["appName"],k["appVendorName"])
    totalcsv+=data
    with open('java.csv', 'w') as f:
        f.write(data)
    table_id = "JavaApps"
    filename = "java.csv"
    response=CreateBigQueryTable(filename, project, dataset_id, table_id, "csv")
    print(response)
with open('java_all.csv', 'w') as f:
        f.write(totalcsv)

### Getting a CSV of all endpoints
with open('endpoints.csv', 'w') as f:
    f.write(GetEndpoints())


### creating tables

table_id = "SentinelOneData"
filename = "endpoints.csv"
response=CreateBigQueryTable(filename, project, dataset_id, table_id,"csv")
print(response)


table_id = "JamfComputers"
filename = "computers.jsonl"
response=CreateBigQueryTable(filename, project, dataset_id, table_id, "json")
print(response)


table_id = "IntuneComputers"
filename = "intunecomputers.jsonl"
response=CreateBigQueryTable(filename, project, dataset_id, table_id, "json")
print(response)

