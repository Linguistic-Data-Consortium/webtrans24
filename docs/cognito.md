# Cognito setup for WebTrans

## Introduction

WebTrans uses Cognito to authorize access to data stored in S3

## How to

### Create an identity pool

* Go to the _Identity pools_ section of the [Cognito web console](https://console.aws.amazon.com/cognito/v2/identity/identity-pools)
* Click the _Create identity pool_ button in the upper right hand corner of the page
* Follow the identity pool creation workflow:
  * Step 1 - Select _Authenticated access_; a set of checkboxes labeled _Authenticated identity sources_ will appear. Select only _Custom developer provider_
  * Step 2 - Select _Create a new IAM role_ and enter a name in the _IAM role name_ text box
  * Step 3 - Enter a name in _Developer provider name_
  * Step 4 - Enter a name in _Identity pool name_ section; make sure the _Activate basic flow_ checkbox is NOT checked.
  * Step 5 - Confirm that information is right, then click _Create identity pool_

### Assign permissions to the new role

* Navigate to the _Roles_ section of the [IAM web console](https://console.aws.amazon.com/iam/home#/roles)
* Find the role you created in step 1 - there's a search box at the top of the role list and click the name to get to the detail page
* In the _Permissions_ section of the role detail page, select _Create inline policy_ from the _Add permissions_ dropdown
* Follow the create policy workflow
  * Step 1
    * Select _S3_ from the _Service_ dropdown
    * In the _Actions allowed_ section that appears, select _ListAllMyBuckets_ and _ListBucket_ in the _List_ subsection, and _GetObject_ under the _Read_ subsection
    * After selecting the permissions, the _Resources_ section below the _Actions allowed_ checkboxes will become enabled; make sure the _Specific_ radio button is selected.
    * There should be two links titled _Add ARNs_, one in the _bucket_ subsection and one in the _object_ subsection.
      * bucket - in the _Resource bucket name_ textbox, enter the name of the bucket you'll be using to store your data
      * object - in the _Resources bucket name_ textbox, enter the bucket name; select the _Any object name_ checkbox next to the _Resource object name_ textbox
  * Step 2
    * enter a name in the _Policy Name_ textbox and click _Create policy_
  
### Configure WebTrans

NOTE: the file paths below are all relative to the directory into which you cloned webtrans

Edit _.envv/development/aws_

* `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION` should be your AWS credentials and the region where you created the identity pool
* `COGNITO_POOL_ID` can be found on the detail page for the identity pool you created in step 1 - the ID will look something like _us-east-1:01234567-89ab-cdef-0123-456789abcdef_, with the first part of the string matching the region with the identity pool
* `COGNITO_PROVIDER_NAME` is the _Developer provider name_ you chose in [Create an identity pool](#create-an-identity-pool)
