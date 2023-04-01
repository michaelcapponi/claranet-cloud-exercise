<!-- BEGIN_TF_DOCS -->
# README #

## Description

**Claranet Exercise | Phoenix**

___

## Documentation

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 4.59 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.60.0 |

___

## Contents

### Folder: claranet-app-infrastructure

Contains terraform manifests to deploy AWS infrastructure and set up the application inside EC2 instance.

The application is deployed whithin an EC2 instance belonging to an ASG in a private VPC subnet and behind an ALB in a public VPC Subnet.
The database is deployed as a DocumentDB instance in the private subnet and the master password is secured in a secret within secret manager.



### Folder: claranet-infr-pipeline

Leverage AWS Codepipeline to build an automated way to deploy application infrastructure downloading the code from github.

The CodePipeline has 4 stages:
- the Source stage which gets the code from Github
- the validate stage which validates the Terraform files with "tflint" command.
- the "Checkov Test" stage to look for any security or compliance problems
- the last stage will generate a plan file with "Terraform Plan" and then apply it.

___

## Installation and Use

Download the git repository.

- If you want to deploy and setup the application infrastructure, navigate into the claranet-app-infrastructure folder.

    There, you may want to setup the backend for your terraform infrastructure. <br>
    An example, based on s3 bucket as backed, is left commented in the code. 

    From here, run:
    - #initialize the terraform repo files, providers and backend <br>
    **terraform init**
    - #check which resources is going to create and save them in tfplan file <br>
    **terraform plan -out=tfplan**
    - #deploy resources <br>
    **terraform apply "tfplan"** <br>
    
    Once all resources have been deployed, you can navigate the AWS console to get the ALB DNS name to navigate and interrogate your application.

- If you want to directly automate your application infrastructure deployment into AWS, whenever you change your Github repo, navigate into the claranet-infr-pipeline.

    There, you may want to setup the backend for your terraform infrastructure. <br>
    An example, based on s3 bucket as backed, is left commented in the code. 

    **Prerequisites**: 
    
    The code builds a Codepipeline with a Github repository as the source and also asks for a Github token to setup the connection. 

    Note that the pipeline runs the first time when you deploy it and then every time the Github repo branch you indicate is updated.

    You need to create a Github repository and upload the **claranet-app-infrastructure** folder to make the Codepipeline work. Also you need a Github token with privileges to access to the new repo.

    Once you are done with these pre-settings, the code will ask you for the following variables when launching terraform:
    - Owner (the github owner username)
    - Repository name
    - Branch (the branch you want to deploy)
    - Github Token

    Now, you are ready to run:
    - #initialize the terraform repo files, providers and backend <br>
    **terraform init**
    - #check which resources is going to create and save them in tfplan file <br>
    **terraform plan -out=tfplan**
    - #deploy resources <br>
    **terraform apply "tfplan"** <br>

    

### Bug Reports & Feature Requests

Write to michaelcapponi96@gmail.com

<!-- END_TF_DOCS -->