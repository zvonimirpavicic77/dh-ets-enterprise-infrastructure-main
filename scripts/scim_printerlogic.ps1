$TOKEN="fplAiEbr02UMeo4cQlqExQrM2VdP7R4jk4j7F2Vs"
$URi="https://gw.app.printercloud5.com/deliveryhero/scim/v2"

$PrinterLogicGermanyid="61c03f18-6e6e-11ee-b57b-06f5620ff00c"
$csvheader="Email","FirstName","LastName","WorkdayID"
$csvpath = "/Users/narbeh/Downloads/iiqtest6.csv"
$csv = Import-Csv -path $csvpath -Header $csvheader -Delimiter ";"



$headers = @{
  "Content-Type"="application/scim+json; charset=utf-8"
  "Authorization"= "Bearer $TOKEN"
  "Accept-Encoding" ="utf-8"
  "Accept-Charset" ="utf-8"
   }

#$response=Invoke-RestMethod -Uri "$($Uri)/Users" -Method Get -headers $headers
#$json=$response.Resources | ConvertTo-Json -Depth 10 | ConvertFrom-Json



Function UpdateSCIMUserAuthPin([string]$UID,[string]$AuthPinUser,[string]$AuthPin)
{

  $body= @"
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:PatchOp",
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
  ],
  "authPinUser": "$AuthPinUser",
  "authPin": "$AuthPin"
        
}
"@ | ConvertTo-json| ConvertFrom-Json


  $response=Invoke-RestMethod -Uri "$($Uri)/Users/$($UID)" -Method Patch  -headers $headers -body $body

  return $response.Resources  

}

Function UpdateSCIMUserEmail([string]$UID,[string]$Email)
{

  $body= @"
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:PatchOp"
  ],
    "emails": [
            {
                "primary":true,
                "value": "$Email",
                "type": "work"
            }
        ]
        
}
"@ | ConvertTo-json| ConvertFrom-Json


  $response=Invoke-RestMethod -Uri "$($Uri)/Users/$($UID)" -Method Patch  -headers $headers -body $body

  return $response.Resources  

}




Function GetSCIMUser([string]$Email)
{
  $response=Invoke-RestMethod -Uri "$($Uri)/Users?filter=userName eq $($Email)" -Method Get -headers $headers
  return $response.Resources  

}


Function CreateSCIMUser([string]$Email,[string]$FirstName,[string]$LastName,[string]$workdayid)
{

$password=-join (((48..57)+(65..90)+(97..122)) * 80 |Get-Random -Count 12 |%{[char]$_})
$body= @"
{
"schemas": [
"urn:ietf:params:scim:schemas:core:2.0:User",
"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
],
"userName": "$Email",
"password": "$password",
"name": {
"givenName": "$FirstName",
"familyName": "$LastName"
},
"emails": [
{
"value": "$Email"
}
],
"displayName": "$FirstName $LastName",
"active": true,
"externalId" : "$workdayid"
}

"@ | ConvertTo-json| ConvertFrom-Json

$response=Invoke-RestMethod -Uri "$($Uri)/Users" -Method POST -headers $headers -body $body
return $response.id  

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


$ArrayList=@()
$newcount=0
$existingcount=0
#iterate through CSV entries
foreach($var in $csv)
  {
  if ($var.Email -eq "") {
      continue
  }

$ExistingUser=GetSCIMUser($var.Email)
if ($ExistingUser.id -eq $null)
  {
    $newcount++
    write-host "New accounts $($var.WorkdayID) $($var.Email)"
  ## User doesn't exist. Creating user
  $userid=CreateSCIMUser -Email $var.Email -FirstName $var.FirstName -LastName $var.LastName -workdayid $var.workdayid
  write-host "$($userid) Created"
  AddScimUserToGroup -userid $userid -groupid $PrinterLogicGermanyid

  } 
else 
  {
    $existingcount++
  UpdateSCIMUserEmail -UID $ExistingUser.id -Email $ExistingUser.userName
  write-host "Existing accounts $($ExistingUser.id) $($ExistingUser.userName)"

  $ArrayList +=  [PSCustomObject]@{
        id     = $ExistingUser.id
        userName    = $ExistingUser.userName
    }
  }


}


write-host "New accounts $($newcount)"
write-host "Existing accounts $($existingcount)"
$ArrayList | export-csv Existingaccounts6.csv -Encoding UTF8



#### check No Badge users ####

$csvheader="Username","Email","Entity","Location","HRIS","SourceId","Country"
$csvpath = "/Users/narbeh/Downloads/printingMergeNarbe2.csv"
$csv = Import-Csv -path $csvpath -Header $csvheader -Delimiter ","

foreach ($user in $csv)
{

$response=GetSCIMUser($user.Email)
 if ($response.badgeId -eq $NULL -and $response.userName -eq $user.Email) {
  Write-Output "userName=$($response.userName) badgeId=$($response.badgeId) Email=$($user.Email)"
  
  }

}

---------------------------------------------------------------------------------------------------------------------------------------------
Update User [Multi-valued properties]

{
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
            {
            "op": "Replace",
            "path": "emails[type eq \"work\"].value",
            "value": "updatedEmail@microsoft.com"
            },
            {
            "op": "Replace",
            "path": "name.familyName",
            "value": "updatedFamilyName"
            }
    ]
}



Update User [Single-valued properties]

{
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [{
        "op": "Replace",
        "path": "userName",
        "value": "5b50642d-79fc-4410-9e90-4c077cdd1a59@testuser.com"
    }]
}


Update Group [Add Members]

{
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [{
        "op": "Add",
        "path": "members",
        "value": [{
            "$ref": null,
            "value": "f648f8d5ea4e4cd38e9c"
        }]
    }]
}



Update Group [Remove Members]

{
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [{
        "op": "Remove",
        "path": "members",
        "value": [{
            "$ref": null,
            "value": "f648f8d5ea4e4cd38e9c"
        }]
    }]
}



DELETE /Users/UserID
DELETE /Groups/GroupID