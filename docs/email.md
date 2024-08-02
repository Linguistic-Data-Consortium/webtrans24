# Setting up email for WebTrans

## Overview

WebTrans uses email for some administrative-type tasks - confirming new user signups and password resets. There's a lot of ways to set this up, so let's begin by stating what we need out of the process:

* SMTP server address - the address of an SMTP server you can use to send email
* SMTP server port - the port used by the SMTP server
* SMTP user name - a user name used to authenticate when sending mail
* SMTP password - the user's password

## Possible strategies

* Use AWS' [Simple Email Service](https://console.aws.amazon.com/ses/home#/account) (SES)
* Use free email service like GMail
* Use your organization's email servers

LDC uses SES

## Other resources

* [Simple Email Service documentation](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html)
