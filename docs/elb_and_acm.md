# Setting up ELB and ACM

## Overview

Elastic Load Balancer (ELB) is an AWS service is a managed load balancer that we'll use to handle public web traffic and TLS termination. AWS Certificate Manager (ACM) is a secure SSL/TLS certificate management service that integrates with ELB.

## How To

### Create a load balancer security group

* Go to the __Security Groups___ section of the [EC2 web console](https://console.aws.amazon.com/ec2/home#SecurityGroups:), then click __Create security group__
* Configure the new security group
  * __Basic details__
    * Enter a name in __Security group name__
    * Enter a description
    * Select the VPC where you are deploying WebTrans
  * __Inbound rules__  
    * Edit the automatically added inbound rule
      * Select `HTTP` from the __Type__ drop down list
      * Select `Anywhere-IPv4` from the __Source__ drop down list
    * Click __Add rule__
      * Select `HTTPS` from the __Type__ drop down list
      * Select `Anywhere-IPv4` from the __Source__ drop down list
  * __Outbound rules__
    * Click __Delete__ next to the default outbound
    * For each subnet[^elb-sg-outbound-subnets] in your VPC:
      * Click __Add rule__
      * Select `Custom TCP` form the __Type__ drop down list
      * Enter `3000` in the __Port range__ text box
      * Select `Custom` from the __Destination__ drop down list
      * Enter the subnet's CIDR block
    * Click __Save rules__

### Create application security group

* Go to the __Security Groups__ section of the [EC2 web console](https://console.aws.amazon.com/ec2/home#SecurityGroups:), then click __Create security group__
* Configure the new security group
  * __Basic details__
    * Enter a name in __Security group name__
    * Enter a description
    * Select the VPC where you are deploying WebTrans
  * __Inbound rules__  
    * Delete the automatically added inbound rule
    * Click __Add rule__
      * Select `Custom TCP` form the __Type__ drop down list
      * Enter `3000` in the __Port range__ text box
      * Select `Custom` from the __Destination__ drop down list
      * Click the text box next to the __Source__ drop down list, scroll to the __Security Groups__ section, then choose the load balancer security group you created earlier.
  * __Outbound rules__
    There should be an automatically added outbound rule with `All traffic` selected in __Type__ and `Custom` selected for __Destination__
    * Click __Delete__ next to the default outbound
    * Click __Add rule__
      * Select `HTTPS` form the __Type__ drop down list
      * Select `Anywhere-IPv4` from the __Destination__ drop down list
    * Click __Add rule__
      * Select `PostgreSQL` form the __Type__ drop down list
      * Select `Custom` from the __Destination__ drop down list
      * Click the text box next to the __Source__ drop down list, scroll to the __Security Groups__ section, then choose the security group you created when [setting up RDS](rds.md).
    * Click __Save rules__

### Request a certificate in ACM

_note: this assumes you've [set up Route 53](dns.md)_

* Go to the __Request certificate__ part of the [ACM web console](https://console.aws.amazon.com/acm/home#/certificates/request), then follow the workflow:
  * Make sure __Request a public certificate__ is selected, then click __Next__
  * in the __Fully qualified domain name__ textbox, enter the fully qualified domain name (FQDN) you'll be using for WebTrans; for example, given the URL `https://webtrans.research.example.com/`, the FQDN would be `webtrans.research.example.com`.
  * Make sure __DNS validation__ is selected
  * Click __Request__; you'll be sent to a detail page for the certificate you requested
* In the __Domains__ subsection of the detail page, click the __Create records in Route 53__ button, then click __Create records__

### Create a target group

* Go to the __Target groups__ section of the [ECS web console](https://console.aws.amazon.com/ec2/home#TargetGroups:).
* Click __Create target group__, then follow the workflow:
  * Select the __IP addresses__ target type
  * Enter a target group name
  * In the __Protocol:Port__ subsection, make sure `HTTP` is selected, then enter `3000` as port number (this replaces the default value of `80`)
  * Make sure you have selected the appropriate entry from the __VPC__ drop down list, then click __Next__, then click __Create target group__

### Create a load balancer

* Go to the __Load balancers__ section of the [EC2 web console](https://console.aws.amazon.com/ec2/home#LoadBalancers:), click the __Create load balancer__ button, then click __Create__ in __Application Load Balancer__ subsection
* In the __Basic configuration__ section
  * Enter a load balancer name
  * Make sure that `Internet-facing` is selected under __Scheme__
  * Make sure that `IPv4` is selected under __Load balancer IP address type__[^lb-ip-type]
* In the __Network mapping__ section
  * Select the VPC in which you're deploying
  * Check at least 2 of the options under __Availability Zones__
  * Choose an appropriate subnet in each of the availability zones; note that it must be a public subnet
* In the __Security groups__ section
  * Remove the entry for the default security group
  * Select the load balancer security group you [created earlier](#create-a-load-balancer-security-group)
* In the __Listeners and routing__ section
  * Select `HTTPS` from the __Protocol__ drop down list, then select the target group you [created earlier](#create-a-target-group) from the __Default action__ drop down list
* In the __Secure listener settings__ section
  * Make sure that __From ACM__ is selected in __Certificate source__
  * Select the ACM certificate that you [created earlier](#request-a-certificate-in-acm)
* Click __Create load balancer__; you'll be redirected to the detail page for the new load balancer

### Update Route53

* Go to the __Hosted zones__ section of the [Route53 web console](https://console.aws.amazon.com/route53/v2/hostedzones#)
* Select the hosted zone you're using to deploy WebTrans
* Click __Create record__
* Enter the host name and any subdomain portion in the __Record name__ textbox  
  note: this text plus the domain name afterwards should be the same as the FQDN you chose when [requesting an ACM certificate](#request-a-certificate-in-acm)
* Select `A - Routes traffic to an IPv4 address and some AWS resources` from the __Record type__ drop down list
* Turn on the __Alias__ slider button
* Under __Route traffic to__
  * Select `Alias to Application and Classic Load Balancer`
  * Select your AWS regions from the drop down list
  * Select the load balancer you [created earlier](#create-a-load-balancer)
* Click __Create records__

[^elb-sg-outbound-subnets]: This does not actually need to be all of your subnets, just the ones in which you might be launching the application container. The default setup described here assumes that you'll be deploying your containers in a public subnet (that is, one attached to an internet gateway), so you only really need to add those.
[^lb-ip-type]: You could pick one of the other options, too, depending on how your network is configured. If a VPC doesn't support a IPv6 addressing, it won't be selectable in the __Network mapping__ section.
