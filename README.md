# Pain Control Infrastructure

## How to login with AWS

The Project works with an AWS service account using the default AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

## Considerations

- The project works with an S3 [backend](https://www.terraform.io/docs/backends/index.html) to persist the terraform state
- The S3 backend configuration is generated on the flight in the CI/CD Pipeline, with this variables TF_BE_BUCKET, TF_BE_BUCKET_KEY
- The project has 2 workspaces
 - tst: for e2e infrastructure testing.
 - prod: Productive environment configuration.

## How to deploy the infrastructure

### Initialize the project (just once)

- `terraform init`: Initialize the terraform project (download providers, establish connection to the cloud project)

### With every change in the terraform code

- `terraform validate`: Validate the code syntax

- `terraform plan`: Diff between state and current code

- `terraform apply`: Take the plan and execute the changes in the cloud

### Destroy infrastructure

- `terraform destroy`: Go to the state and destroys all the infrastructure that is in the state



## About testing 
For testing the infrastructure we use the [terraform-compliance](https://terraform-compliance.com/). 

### About terraform compliance
`terraform-compliance` is a lightweight, security and compliance focused test framework against terraform to enable negative testing capability for your infrastructure-as-code.

#### Instructions to run test using the library

- __Install the library:__ Ensure to install the library by `pip` or `docker`
- __Plan as Json:__ Ensure to save the terraform plan as json
    1. `terraform plan -out terraform.out`
    2. `terraform show -json terraform.out > plan.json`

- __Run test:__  Now, you will run the tests in the folder to test: Ex: tests
    1. `terraform-compliance -p plan.json -f tests`


## About environments
For different environments, we use workspaces:

Ex: to dev environment we use workspace "dev"

- __Create new workspace:__  

    1. `terraform workspace new dev`

- __Select workspace created:__ 

    2. `terraform workspace select dev`

- __Execute plan:__ 

    3. `terraform plan -workspace=dev`

- __Execute apply:__ 

    4. `terraform apply -workspace=dev`

