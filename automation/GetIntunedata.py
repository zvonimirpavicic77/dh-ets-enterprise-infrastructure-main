import requests
import json
import os
from dotenv import load_dotenv


load_dotenv(".env")
azure_appId=os.getenv("azure_appId")
azure_appSecret=os.getenv("azure_appSecret")
azure_tenantId=os.getenv("azure_tenantId")


def get_token():
    body = {
        "resource": "https://api.manage.microsoft.com/",
        "client_id": azure_appId,
        "client_secret": azure_appSecret,
        "grant_type": "client_credentials"
    }
    response = requests.post("https://login.windows.net/" + azure_tenantId + "/oauth2/token", data=body)
    return response.json()["access_token"]


def get_devices(auth_token):
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': "Bearer " + auth_token
    }
    skip = 0
    top = 1000
    results = list()
    processing_machines_continue = True
    while processing_machines_continue:
        url = "https://fef.msub06.manage.microsoft.com/ReportingService/DataWarehouseFEService/devices?api-version=v1.0&$skip= " + str(skip) + " &$top=" + str(top)
        response = requests.get(url, headers=headers)
        if response.json()['value'] != list():
            results += response.json()['value']
            skip += top
        else:
            processing_machines_continue = False
    return results

response_dict=get_devices(get_token())


with open('intunecomputers.jsonl', 'w') as jsonl_output:
    for entry in response_dict:
        json.dump(entry, jsonl_output)
        jsonl_output.write('\n')
