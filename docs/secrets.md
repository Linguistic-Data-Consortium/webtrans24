# Setting up application secrets

WebTrans uses several pieces of sensitive information that must be kept confidential, which we will keep in Secrets Manager (SM).

## Which secrets we need

* __SMTP password__ - webtrans sends email to handle new user signups and password resets; actually setting up an email service is beyond the scope of this guide
* __Secret Key Base__ - webtrans uses this value to encrypt client-side session data and sign cookies; it should be a 128 character hexadecimal string.
  a convenient way to generate the value is using the rails cli:  

  ```sh
    bin/rails secret
  ```

* __Postgres password__ - this is used to connect the database.

## Notes

* Database setup is going to be a pain
* explain how to run `rails secret` using the local development containers
