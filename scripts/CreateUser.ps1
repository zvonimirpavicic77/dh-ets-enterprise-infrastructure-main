Function CreateUser([string]$Email,[string]$FirstName,[string]$LastName,[string]$workdayid)
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