# Setting up application secrets

WebTrans uses several pieces of sensitive information that must be kept confidential, which we will keep in Secrets Manager (SM).

## Which secrets we need

* __SMTP password__ - webtrans sends email to handle new user signups and password resets; actually setting up an email service is beyond the scope of this guide
* __Postgres password__ - this is used to connect the database; you created it as part of setting up [RDS](rds.md)
* __Secret Key Base__ - webtrans uses this value to encrypt client-side session data and sign cookies; it should be a 128 character hexadecimal string.
  a convenient way to generate the value is using the rails cli:  

  ```sh
    bin/rails secret
  ```

## Storing secrets in Secrets Manager

* Go to the [Secrets Manager web console](https://console.aws.amazon.com/secretsmanager/listsecrets)
* For each secret, click the __Store a new secret__ button and follow the workflow
  * Step 1
    * In the __Secret type__ section, select `Other type of secret`
    * In the __Key/value pairs__ section, click __Plaintext__,
    * Delete the contents of the text area and paste in your secret, then click __Next__
  * Step 2
    * In the __Secret name and description__ section, give a name and description for the secret; then click __Next__
  * Step 3
    * Skip automatic secret rotation
  * Step 4
    * Review the information, then click __Store__

## Notes

* Database setup is going to be a pain
* explain how to run `rails secret` using the local development containers
