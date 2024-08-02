# Deploying WebTrans on AWS

## Overview

This guide covers how to deploy an instance of WebTrans on AWS.

### Installation

* [Create Cognito identity pool](cognito.md)
* [Create RDS database](rds.md)
* [Set up DNS](dns.md)
* [Set up email](dns.md)
* [Create and store secrets](secrets.md)
* [Set up ELB and ACM](elb_and_acm.md)
* [Set up ECR and ECS](ecr_and_ecs.md)
* [Configure CORS for S3](cors.md)

### Troubleshooting

#### WebTrans problems

##### My audio doesn't load

* Check to make sure the s3 permissions you granted the grant permission to the object
* If you're using bucket encryption with a customer managed KMS key, make sure the role used for the Cognito identity pool has the `KMS:Decrypt` permission for the key(s) used to encrypt the bucket

### Other resources

* AWS [documentation](https://docs.aws.amazon.com)

## Bob's notes

Maybe explain/point out where some options could be changed from what's described. You don't _need_ to use RDS, ELB, ACM, etc.
