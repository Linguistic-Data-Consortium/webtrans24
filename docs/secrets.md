# Storing application secrets in Secrets Manager

WebTrans uses several pieces of information that must be kept confidential, which we will keep in Secrets Manager (SM).

## Which secrets we need

* __SMTP password__ - webtrans sends email to handle new user signups and password resets; actually setting up an email service is beyond the scope of this guide
* __Postgres password__ - this is used to connect the database; you created it as part of setting up [RDS](rds.md)
* __Secret Key Base__ - webtrans uses this value to encrypt client-side session data and sign cookies; it should be a 128 character hexadecimal string.

## Generating secrets

Rails provides a function for generating random values suitable for __Secret Key Base__. It can be run in docker as:

```sh
docker compose exec web bundle exec rails secret
```

The AWS CLI can also generate random passwords[^get-random-password-is-an-api-call], e.g., to generate a 32 character random password without punctuation characters:

```sh
aws secretsmanager get-random-password --password-length 32 --exclude-punctuation
```

## Storing secrets in Secrets Manager

* Go to the [Secrets Manager web console](https://console.aws.amazon.com/secretsmanager/listsecrets)
* For each secret, click the __Store a new secret__ button and follow the workflow
  * Step 1
    * In the __Secret type__ section, select `Other type of secret`
    * In the __Key/value pairs__ section, click __Plaintext__,
    * Delete the contents of the text area and paste in your secret, then click __Next__
  * Step 2
    * In the __Secret name and description__ section, give a name[^naming-secrets] and description for the secret; then click __Next__
  * Step 3
    * Skip automatic secret rotation
  * Step 4
    * Review the information, then click __Store__

[^naming-secrets]: You can pick any valid name for your secrets, but I recommend using a naming scheme with a common string embedded in the name, like `webtrans/smtp_password`, `webtrans/postgres_password`, etc., as it makes it a bit easier to write IAM policies that cover all the relevant secrets.

[^get-random-password-is-an-api-call]: `aws secretsmanager get-random-password` makes an API call to generate the password.
