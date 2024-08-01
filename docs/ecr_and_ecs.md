# Deploying WebTrans on ECS

## Overview

Elastic Container Service (ECS) is a managed platform for deploying Docker-compatible container images in AWS. Elastic Container Registry (ECR) is Docker registry as-a-service, which we'll use to host the WebTrans image.

## How to

### Create a repository for images

Open the __Repositories__ section of the [ECR web console](https://console.aws.amazon.com/ecr/private-registry/repositories) then click the __Create repository__ button at the upper right. Enter a repository name, then click __Create repository__.  

Once the repository has been created, you can see it in the list of repositories; note the `URI` column has the URI for your repository, which you'll need to [build and push the image](#build-and-push-the-image)/

### Create an ECS cluster

Open the [Clusters](https://console.aws.amazon.com/ecs/v2/clusters) section of the ECS web console, then click the _Create cluster_ button at the upper right. Enter a cluster name , make sure that `AWS Fargate` is checked in the __Infrastructure__ section, then click __Create__.

### Build and push the image

In this section, `${region}` is your AWS region and `${repository_uri}` is the URI of the repository you [created earlier](#create-a-repository-for-images). `${registry_uri}` is the just the host name portion of `${repository_uri}` , e.g., if `${repository_uri}` is `123456789012.dkr.ecr.us-east-1.amazonaws.com/webtrans/app`, then `${registry_uri}` would be `123456789012.dkr.ecr.us-east-1.amazonaws.com`. `${image_uri}` is a string in the form `${repository_uri}:${tag}` where tag is a string that identifies a particular image in the repository. If `${tag}` is `prod`, then `${image_uri}` in this example would be `123456789012.dkr.ecr.us-east-1.amazonaws.com/webtrans/app:prod`

* Make sure you've followed the instructions in [Local Installation](../README.md#local-installation) before continuing
* Make sure you've installed and configured the [AWS CLI](https://aws.amazon.com/cli/)
* Authenticate with the registry using the AWS CLI:  
  `aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${registry_uri}`
* Build the image:  
  `docker build -t ${image_uri} .`
* Push the image:  
  `docker push ${image_uri}`

### Create and register an ECS task description

ECS task descriptions describe one or more containers in a deployment; think of them as analogous to `docker-compose.yml` files.

Edit the task description [template](task_description.json) to suit your deployment with values, using the following information as a guide. Apart from the `executionRoleArn` and `taskRoleArn`, you only need to configure things for the `app` container definition.

#### `executionRoleArn` and `taskRoleArn`

__These are the ARNs for the roles that I haven't written the docs for just yet. stay tuned.__

#### `image`

The URI of the webtrans image to run; this is the value of `${image_uri}` from the [Build and push image](#build-and-push-the-image) section.

#### `environment`

This section is a list of `name`/`value` pairs environment variables that will be set in the container; take care to only change the `value`s.

* `ACTIVE_STORAGE_BUCKET` - the S3 bucket you're using for webtrans data
* `COGNITO_POOL_ID` - the ID of the Cognito identity pool to use for WebTrans; see the detail page for the identity pool in the [Cognito web console](https://console.aws.amazon.com/cognito/v2/identity/identity-pools)
* `COGNITO_PROVIDER_NAME` - this is the developer provider name we chose when [setting up Cognito](cognito.md)
* `DATABASE_HOST` - your database host name; if using RDS, this is the value labeled _Endpoint_ on the _Connectivity & security_ tab of the detail page for your db instance in the [RDS web console](https://console.aws.amazon.com/rds/home#databases:).
* `SMTP_HOST` - the address of your SMTP server
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

* Go to the __Task definitions__ section of the [ECS web console](https://console.aws.amazon.com/ecs/v2/task-definitions)
* From the __Create new task definition__ drop down list, select `Create new task definition with JSON`
  * Completely delete the contents of the task definition textarea
  * Paste in the contents of the task definition edited above
* Click __Create__

## Create and start service

* Open the [Clusters](https://console.aws.amazon.com/ecs/v2/clusters) section of the ECS web console, then click the name of the cluster [you created earlier](#create-an-ecs-cluster)
* In the __Services__ tab, click __Create__
  * Select `Launch type` in the __Environment__ section
  * In the  __Deployment configuration__ section
    * Select `webtrans` from the __Family__ drop down list
    * Enter a service name
  
## External links

* [ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
* ECS Console
  * [Clusters](https://console.aws.amazon.com/ecs/v2/clusters)
  * [Task Definitions](https://console.aws.amazon.com/ecs/v2/task-definitions)
* [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
  * [Private registry authentication in Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html)
* [ECR Repositories](https://console.aws.amazon.com/ecr/private-registry/repositories)

