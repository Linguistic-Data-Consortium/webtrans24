# Cognito setup for WebTrans

## Introduction

WebTrans uses Cognito to authorize access to data stored in S3

## How to

### Create an identity pool

* Go to the __Identity pools__ section of the [Cognito web console](https://console.aws.amazon.com/cognito/v2/identity/identity-pools)
* Click the __Create identity pool___ button in the upper right hand corner of the page
* Follow the identity pool creation workflow:
  * Step 1 - Select __Authenticated access__; a set of checkboxes labeled __Authenticated identity sources__ will appear. Select only __Custom developer provider__
  * Step 2 - Select __Create a new IAM role__ and enter a name in the __IAM role name__ text box
  * Step 3 - Enter a name in __Developer provider name__
  * Step 4 - Enter a name in __Identity pool name__ section; make sure the __Activate basic flow__ checkbox is NOT checked.
  * Step 5 - Confirm that information is right, then click __Create identity pool__

### Assign permissions to the new role

* Navigate to the __Roles__ section of the [IAM web console](https://console.aws.amazon.com/iam/home#/roles)
* Find the role you created in step 1 - there's a search box at the top of the role list and click the name to get to the detail page
* In the __Permissions__ section of the role detail page, select `Create inline policy` from the __Add permissions__ drop down
* Follow the create policy workflow
  * Step 1
    * Select `S3` from the __Service__ dropdown
    * In the __Actions allowed__ section that appears, select `ListAllMyBuckets` and `ListBucket` in the __List__ subsection, and `GetObject` under the __Read__ subsection
    * After selecting the permissions, the __Resources__ section wil be enabled; make sure the __Specific__ radio button is selected.
    * There should be two links titled __Add ARNs__, one in the __bucket__ subsection and one in the __object__ subsection.
      * bucket - in the __Resource bucket name__ textbox, enter the name of the bucket you'll be using to store your data
      * object - in the __Resources bucket name__ textbox, enter the bucket name; select the __Any object name__ checkbox next to the __Resource object name__ textbox
  * Step 2
    * enter a name in the __Policy Name__ textbox and click __Create policy__
  
### Configure WebTrans

NOTE: the file paths below are all relative to the directory into which you cloned Webtrans

Edit _.envv/development/aws_

* `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION` should be your AWS credentials and the region where you created the identity pool
* `COGNITO_POOL_ID` can be found on the detail page for the identity pool you created in step 1 - the ID will look something like _us-east-1:01234567-89ab-cdef-0123-456789abcdef_, with the first part of the string matching the region with the identity pool
* `COGNITO_PROVIDER_NAME` is the _Developer provider name_ you chose in [Create an identity pool](#create-an-identity-pool)
