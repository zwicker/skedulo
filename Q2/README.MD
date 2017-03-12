# Node App RUN
docker run -d -p 3000:3000 --name node-app zwicker/node-app

# GOLANG APP Start
docker run -it --rm -d -p 8080:8080 --name golang-app zwicker/go-app

# FULL DEPLOY - Directions
Install Terraform then enter AWS details into "variables.tf"

Put the AWS private key file in this directory and set the relevant AWS configuration variables in variables.tf

This terraform command will create a new terraform plan and build the following in AWS leveraging docker containers on EC2 instances.
* VPC
* Subnet
* Security Group
* Load Balancer
* 2 Web Servers with a Go server and JS Server running in Docker containers in each.

```
terraform plan
terraform apply
```
