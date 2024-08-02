# Setting up DNS with Route53

## Why this matters

Domain Name System (DNS) is a service that maps internet host names to network addresses. Apart from making web addresses more user friendly, web browsers require the DNS name of the server its connecting to match the name on the SSL/TLS certificate used to secure the connection.

## How to

### Set up a hosted zone

A hosted zone is a domain for which Route53 is the authoritative DNS server.

This is still incomplete

* [Instructions](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/creating-migrating.html) for delegating a subdomain to Route53
* Find/write instructions for registering a domain and setting up Route53's NS/SOA records
  * I think they might automagicaly handle SOA

## Other resources

[Route 53 Developer Guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
