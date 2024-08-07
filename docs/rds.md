# Introduction

This guide describes how to use AWS Relational Database Service (RDS) to host a managed PostgreSQL instance that will store the annotations and other application data required by WebTrans.

## Steps

### Create an RDS instance

* Browse to the [Databases section](https://console.aws.amazon.com/rds/home#databases:) of the RDS console, then click the __Create database__ button at the upper right.
* Select `Standard create` in the __Choose a database creation method__ section at the top, then fill out the form. The options below aren't exhaustive and where something isn't explicitly mentioned, you should accept the default value.
  * __Options__
    * __Engine type__ - select `PostgreSQL`
    * __Engine version__ - select `PostgreSQL 16.3-R2`
  * __Availability and durability__ - select `Single DB instance`
  * __Settings__
  * __DB instance identifier__ - enter a name for the database server, e.g. `webtrans-db`
  * __Instance configuration__  
    * Select `Burstable`
    * Select `db.t4g.small` from the drop down  
      _NOTE: this could be any instance type with  >=2 vCPU and >=2 GiB RAM_
  * __Storage__
    * __Storage type__ - select `gp3`
    * __Allocated storage__ - enter `20`  
    * __Enable storage autoscaling__ - uncheck this (_optional_)
  * __Connectivity__
    * __Virtual Private cloud__ - Select a VPC for your database
    * __Public Access__ - Select `Yes`, but please [read this](#public-accessibility-and-security) to understand the choice
    * __VPC security group__ - select `Create new`
      * Enter a security group name, e.g., `webtrans-db-security-group'
  * __Monitoring__
     The defaults are fine here, though I usually turn off `DevOps Guru`.
  * __Additional configuration__
    * _Log exports_ - select `PostgreSQL log` and `Upgrade log`  
     The other options are fine with default values, though you may want to change the backup retention window under the _Backup_ subsection. In addition, you can choose to encrypt your instance data and select which KMS keys are used to encrypt your data.

After clicking _Create instance_, the DB instance will be created and started. This process usually takes a few minutes.

### Set up the WebTrans database

After creating the WebTrans database, you need to configure the database for WebTrans.

* Install the PostgreSQL 16 client on your computer
  * see the [PostgreSQL docs](https://www.postgresql.org/docs/16/index.html) for more information
* Edit `create_db_and_user.sql`:
  * generate a random strong password for the database user, and replace the string `change-me-to-a-better-password` with the newly generated password
    * note: you probably want to avoid single quotes (`'`) in the password, as they will break the script without proper escaping.
* Set environment variables and run script
  * in a shell window, set the following environment variables:
    * `PGHOST` - this can be found under _Endpoint & port_ on the detail page of the database you created
    * `PGUSER` - this should be `postgres`
    * `PGPASSWORD` - this is automatically generated while creating the database; get value from [Secrets Manager](secrets.md)
  * run the following command in the shell you just configured:
    `psql -f create_db_and_user.sql`  
    if all goes well, you'll see the following output:

    ```sql
    CREATE DATABASE
    CREATE ROLE
    ALTER DATABASE

### Update db security group

By default, the new security group created with the RDS instance should traffic from your IP (that is, the one from which you did the setup). To allow the deployed app to access the database, you'll need to adjust the security group rules to allow hosts in your VPC to reach the database.

* Go to the __Subnets__ section of the [VPC web console](https://console.aws.amazon.com/vpcconsole/home#subnets)
  * Make note of the subnet CIDRs for your VPC
    * note that the list has all subnets for your account, regardless of VPC; make sure the subnet addresses are for the right VPC
* Go to the __Security groups__  section of the [EC2 web console](https://console.aws.amazon.com/ec2/home#SecurityGroups:) and click the `Security group ID` of the security group you created while setting RDS
  * Click the __Edit inbound rules__
    * For each of your VPC subnets, click __Add rule__
      * from __Type__ select_ `PostgreSQL`
      * under __Source__ enter the CIDR of the subnet, including subnet mask, e.g.: `10.10.10.0 / 25`
    * When done, click __Save rules__

## Notes

#### Public accessibility and security

In the context of RDS, public accessibility means that the DB instance will be assigned a public IP address and can _potentially_ be accessed by clients outside of the VPC. This option makes it easier to set up and maintain the database and can be changed to `Not publicly accessible` once configuration is complete.

The security risk of exposing the database to the internet can be mitigated , lock down the incoming addresses to a limited range of external addresses and the VPC subnet(s) where you'll be hosting the app.
