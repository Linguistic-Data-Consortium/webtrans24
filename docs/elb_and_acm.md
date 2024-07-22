# Setting up ELB and ACM

NOTE: this isn't done yet

## Overview

Elastic Load Balancer (ELB) is an AWS service is a managed load balancer that we'll use to handle public web traffic and TLS termination. We'll use ELB's integration with AWS Certificate Manager (ACM) to automate issuing TLS certificates.

## How To

### Create a load balancer

Browse to the [Load Balancers](https://console.aws.amazon.com/ec2/home#LoadBalancers:) section of the EC2 console, then click the _Create load balancer_ button, then click the _Create_ for __Application Load Balancer__ in the page that follows. .
