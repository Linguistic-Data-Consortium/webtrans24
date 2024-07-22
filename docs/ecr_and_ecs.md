# Deploying WebTrans on ECS

## Overview

Elastic Container Service (ECS) is a managed platform for deploying Docker-compatible container images in AWS. Elastic Container Registry (ECR) is Docker registry as-a-service, which we'll use to host the WebTrans image.

## How to

### Create an ECS cluster

Open the [Clusters](https://console.aws.amazon.com/ecs/v2/clusters) section of the ECS web console, then click the _Create cluster_ button at the upper right. Enter a  _Cluster name_, make sure that _AWS Fargate_ is checked in the _Infrastructure_ section, then click _Create_.

### Create a repository for images

Open the _Repositories_ section of the [ECR console](https://console.aws.amazon.com/ecr/private-registry/repositories), then click the _Create repository_ button at the upper right. Enter a repository name, then click _Create repository_.  

### Build and push the image

* Build the image  
  TODO: link to other docs or whatever
* If you haven't already, install and configure the [AWS CLI](https://aws.amazon.com/cli/)
* Authenticate with the registry using the cli:

```sh
aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {aws_account_id}.dkr.ecr.{region}.amazonaws.com
```

### Create and register an ECS task description

ECS task descriptions describe one or more containers in a deployment; think of them as analogous to `docker-compose.yml` files.

Edit the task description [template](task_description.json) to suit your deployment with values, using the following information as a guide. Apart from the `executionRoleArn` and `taskRoleArn`, you only need to configure things for the `app` container definition.

#### `executionRoleArn` and `taskRoleArn`

**These are the ARNs for the roles that I haven't written the docs for just yet. stay tuned.**

#### `image`

The URI of the webtrans image to run.  You can find this in the _Repositories_ section of the [ECR web console](https://console.aws.amazon.com/ecr/private-registry/repositories). Remember to include the image tag, e.g. `012345678901.dkr.ecr.us-east-2.amazonaws.com/webtrans/app:prod`.

#### `environment`

  This section is a list of `name`/`value` pairs environment variables that will be set in the container; take care to only change the `value`s.

* `ACTIVE_STORAGE_BUCKET` - the S3 bucket you're using for webtrans data
* `COGNITO_POOL_ID` - the ID of the Cognito identity pool to use for WebTrans; see the detail page for the identity pool in the [](https://console.aws.amazon.com/cognito/v2/identity/identity-pools)
* `COGNITO_PROVIDER_NAME` - this is the _Developer provider name_ we chose when [setting up Cognito](cognito.md)
* `DATABASE_HOST` - your database hostname; if using RDS, this is the value labeled _Endpoint_ on the _Connectivity & security_ tab of the detail page for your db instance in the [RDS web console](https://console.aws.amazon.com/rds/home#databases:).
* `SMTP_HOST` - the address of the SMTP server
* `SMTP_PORT` - the port number to use on the SMTP server
* `SMTP_USER` - the username WebTrans will use to send email
* `POSTGRES_DB` - the name of the webtrans database
* `POSTGRES_USER` - the username used to connect to the database
* `PUBLIC_URL`- the hostname where you'll be serving the website, e.g. `webtrans.example.edu`

#### `secrets`

  Like the `environment` section, this is a list of pairs that correspond to environment variables set in the container. Edit the `valueFrom` to be the ARNs for the [secrets](secrets.md) we set up earlier. There should be 3 secrets to configure:

* `POSTGRES_PASSWORD`
* `SMTP_PASSWORD`
* `SECRET_KEY_BASE`

#### Registering the task description

After writing the task description, register the

## Create and start service

* todo

## External links

* [ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
* ECS Console
  * [Clusters](https://console.aws.amazon.com/ecs/v2/clusters)
  * [Task Definitions](https://console.aws.amazon.com/ecs/v2/task-definitions)
* [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
* [ECR Repositories](https://console.aws.amazon.com/ecr/private-registry/repositories)
