import requests
import json
import os
from dotenv import load_dotenv

load_dotenv(".env")
jamfapiurl=os.getenv("jamfapiurl")
client_id = os.getenv("client_id")
client_secret = os.getenv("client_secret")



def GetJamfAccessToken():
    headers={
        "Content-Type" : "application/x-www-form-urlencoded"
    }

    body={
        "client_id":client_id,
        "grant_type":"client_credentials",
        "client_secret":client_secret
    }
    response= requests.post(url=jamfapiurl+"/api/oauth/token",headers=headers,data=body)
    return response.json()["access_token"]


def GetJamfComputer():

    bearerToken=GetJamfAccessToken()
    headers={
        "Authorization":"Bearer "+bearerToken,
        "Accept":"application/json"
    }
    sections="GENERAL,USER_AND_LOCATION" ###Supported Values are: GENERAL, DISK_ENCRYPTION, PURCHASING, APPLICATIONS, STORAGE, USER_AND_LOCATION, CONFIGURATION_PROFILES, PRINTERS, SERVICES, HARDWARE, LOCAL_USER_ACCOUNTS, CERTIFICATES, ATTACHMENTS, PLUGINS, PACKAGE_RECEIPTS, FONTS, SECURITY, OPERATING_SYSTEM, LICENSED_SOFTWARE, IBEACONS, SOFTWARE_UPDATES, EXTENSION_ATTRIBUTES, CONTENT_CACHING, GROUP_MEMBERSHIPS
    pagesize="&page=0&page-size=2000"
    # apipreview="/api/preview/computers?section="
    apiv1="/api/v1/computers-inventory?section="
    response= requests.get(url=jamfapiurl+apiv1 + sections+pagesize,headers=headers)
    if response.json()["totalCount"] > 2000:
        data=response.json()["results"]
        page=response.json()["totalCount"]/2000
        i=1
        while (i<page):
            pagesize="&page="+str(i)+"&page-size=2000"
            response= requests.get(url=jamfapiurl+apiv1 + sections+pagesize,headers=headers)
            data=data+response.json()["results"]
            i+=1
    return data

def GetComputerGroupMembers(id):
    bearerToken=GetJamfAccessToken()
    headers={
        "Authorization":"Bearer "+bearerToken,
        "Accept":"application/json"
    }
    apiv2 = "/api/v2/computer-groups/smart-group-membership/"+id
    response = requests.get(url=jamfapiurl+apiv2, headers=headers)
    return response.json()["results"]

response_dict = GetJamfComputer()
# javacomps=GetComputerGroupMembers("330")

with open('computers.jsonl', 'w') as jsonl_output:
    for entry in response_dict:
        json.dump(entry, jsonl_output)
        jsonl_output.write('\n')


# with open('javajamfcomputers.jsonl', 'w') as jsonl_output:
#     for entry in javacomps:
#         json.dump(entry, jsonl_output)