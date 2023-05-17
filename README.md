### **1. Introduction**
* ##### This folder contains terraform configuration files to create various resources on aws to deploy multiple  ecs services that are necessary.

* ##### To run these scripts, you will need to create a variable file named client-name.tfvars. This file should contain the values which are mentioned later on in this document:
  
* ##### To create `client-name.tfvars` file you can refer to the **variables.tf** file present in the root directory in this folder. Also given sample values for quick reference. 

#### **How to deploy infrastructure**
There are two ways to deploy the infrastructure:

 **a) Using github actions**
   
  - This is the recommended way to deploy the infrastructure. For this, you  need to create a pull request for the main branch of the repository. Upon successful merging into main branch GitHub Actions will then automatically deploy the infrastructure.

  - github action workflow file that is associated with this repository validates the configuration file and shows all the infrastructure that is planned to be deployed when you raise Pull-request for the main branch.
  -  Carefully follow `prerequisites` and ensure everything is ready.
  -  Upon successful Merge into the main branch the infrastructure will be created depending upon the input variable file which has to be made available in S3. Details about this variable file are mentioned later.
  - This will upload `client-name.tfstate` to the S3-bucket `terraform-gamio-backend` in the corresponding workspace

 
**b) From Local**
  - This is not recommended approach. But given here for reference.   
  - To initiate modules and  install plugins for required providers execute the command after going into this directory.
              
            terraform init -backend-config="bucket=terraform-gamio-backend" -backend-config="key=variable-files/client-name.tfstate" -backend-config="region=$REGION" -upgrade
  - To show any syntax errors
     
         terraform validate

  - To create workspace for the client
    
        terraform workspace new client-name

  - To see what resources are going to be created/destroyed/modified in the cloud
    
          terraform plan -var-file="client-name.tfvars"
  -  To create resources in the cloud depending upon the input values provided in the client-name.tfvars file
  
              terraform apply -var-file="client-name.tfvars"  
                         
            Note: This also displays output variables in the console upon successful execution, save them for reference purpose.

  -  To destroy the resources if no longer required.
    
         terraform destroy -var-file="client-name.tfvars" 



### **2. Prerequisites**
There are some mandatory rules and optional prerequisites. Optional prerequisties can reduce some manual operations if followed properly but not necessary to execute the scripts

**a) Mandatory prerequisites**
* Make sure that `s3_bucket_name` used here for storing env file must have been created before applying `terraform init`. We use already created *s3-bucket* `fargate-cluster-configurations` for this purpose and folder will be created in this bucket for client-configuraton files.

* As backend is configured in s3-bucket, make sure bucket named `terraform-gamio-backend` exists.

* Variable file should have an extention `.tfvars` and file name should be client name and the file should be uploaded to folder *variable-files* in the *s3-bucket*  `terraform-gamio-backend`.
* variable file must have valid key-value pairs and mentioned in the next section for reference and not to be used as it is.

* CIDR values for the vpc should be choosen carefully as it should not match the default vpc present in the regions. It should also be different from other VPCs where our other services are launched as it will be hurdle for creating vpc peerings if need arises later.  

**b) Optional prerequisites**
* Make sure ECR has been setup and the image corresponding to the service has been uploaded to ECR. This provides us with the required image urls in the input variables. Else use some dummy names and reconfigure manually later on.

* This step only for execution from local and you have env-files ready for one or more services. **This can be ignored otherwise**. Keep the env-files with valid names in the env directory at root level in this folder then those files will be uploaded to s3. 
          
        Name of envfile that code expects is defined within the code and you can refer to any of the ecs modules to understand the naming convention.) Note that in case file-name does not exactly matches as it is required then it will upload a dummy env file to the s3 bucket with proper name which you need to replace it manually later on. 
  
          Example:The name of env file to be uploaded depends on other variables: For e.g. if game_name="abc", environment="dev", service_name[i]="contest" then corresponding env should be having the name: abc-dev-contest.env 

* ensure that `ecsrole` mentioned has proper permissions to read env files. Service may fail to update if it does not have enough permission to read envs stored at s3.

---

### **3. Variables**

 In this section we mentioned all  the values that arerequired in variables file.

**a)  Overall application related variables**

* game_name          = "test-client"

* service_name       = ["contest", "cricket", "football", "leaderboard", "payment", "player-analytics", "tenant", "socket", "revenue", "game-analytics", "poker"]

* services_to_launch = [true,        false,      false,         true,    false,       true,           false,    false,     false,      false, true]

* environment        = "dev"

* aws_region           = "us-east-1"


**b)  vpc related variables**

* vpc_cidr_block       = "192.168.0.0/16"

* subnets_cidr_public  = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]

* subnets_cidr_private = ["192.168.3.0/24", "192.168.4.0/24", "192.168.5.0/24"]


**c) load-balancer, ecs and env-file related variables**

* contest_image      = "nginx:latest"

* cricket_image      = "nginx"

* football_image     = "nginx"

* payment_image      = "nginx"

* pl-analytics_image = "nginx"

* leaderboard_image  = "606880623734.dkr.ecr.ap-south-1.amazonaws.com/leaderboard-service:latest"

* tenant_image       = "606880623734.dkr.ecr.ap-south-1.amazonaws.com/tenant:latest"

* target_port        = 3000

* certarn            = "arn:aws:acm:us-east-1:606880623734:certificate/a99a9aad-d80c-4d0e-bafc-97192b94a3b9"

* ecsrole            = "arn:aws:iam::606880623734:role/ecsTaskExecutionRole-b2b-tenant"

* dns_name           = "api-dev.gamio-services.net"

* s3_bucket_name     = "fargate-cluster-configurations"

**d)  poker related variables**

* poker_image = "nginx"
* target_poker_port = 3880

* dns_name_poker    = "poker.gamio-services.net"

---

### **4. Following resources will be created**


**a) VPC**

  - Creates VPC, three public and three private subnets.
  - Creates Route tables for public and private subnets. Associate them to corresponding subnets
  - Creates Internet Gateway 
  - Creates one NAT Gateway and attaches it to the private subnets
  - Creates Elastic IP for NAT Gateway

**b) Security-Groups**

  - Create one security group  for loadbalancer. 
  - Creates one security group for poker service only if that service is launched
  - Creates one common Security group for all remaining services except poker-service
 
**c) Loadbalancer**

  - Creates a loadbalancer
  - Creates HTTP and HTTPS listeners
  - Create listener rules for all services that we are creating

**d) Cloudwatch**

  - Creates cloudwatch group for each service that we want to launch

**e) S3 related**

  - we upload the env files to the already created s3 bucket

**f) ECS related**

  - Creates ecs cluster.
  - Creates task definition for the services mentioned in the input
  - Targetgroups for the services mentioned in the input
  - Creates ecs service for the services mentioned in the input
