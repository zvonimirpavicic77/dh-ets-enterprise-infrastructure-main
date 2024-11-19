$TOKEN="fplAiEbr02UMeo4cQlqExQrM2VdP7R4jk4j7F2Vs"
$URi="https://gw.app.printercloud5.com/deliveryhero/scim/v2"

$PrinterLogicGermanyid="61c03f18-6e6e-11ee-b57b-06f5620ff00c"


$headers = @{
  "Content-Type"="application/scim+json; charset=utf-8"
  "Authorization"= "Bearer $TOKEN"
  "Accept-Encoding" ="utf-8"
  "Accept-Charset" ="utf-8"
   }


function AddScimUserToGroup([string]$userid,[string]$groupid)
{

$body= @"
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:PatchOp"
  ],
  "Operations": [
    {
      "op": "add",
      "path": "members",
      "value": [
        { "value": "$userid" }
      ]
    }
  ]
}
"@ | ConvertTo-json| ConvertFrom-Json

$response=Invoke-RestMethod -Uri "$($Uri)/Groups/$($groupid)" -Method Patch -headers $headers -body $body
}



#### Example how to add a user to PrinterLogicGermany user group
#### AddScimUserToGroup -userid "me@example.com" -groupid $PrinterLogicGermanyid