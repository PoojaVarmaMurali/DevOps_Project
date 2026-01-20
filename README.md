# *Problem statement:*
 ```Design a scalable and fault-tolerant cloud infrastructure on AWS for a fictional web application```

# *AWS Best practices*
```. Multi-AZ deployment for high availability``` <br>
```. Auto scaling group for ECS services``` <br>
```. VPC with public and private subnets isolation``` <br>
```. SG with least privilage``` <br>
```. Encrypted storage and transit ``` <br>
```. CloudWatch monitoring with SNS alerting ``` <br>
```. Secrets Manager for creds management``` <br>

# *Multi-Tier Architecture:*
```. Presentation Tier: CloudFRont CDN + Route  DNS``` <br>
```. Load Balancing: Application LoadBaklancer with SSL termination``` <br>
```. Application Tier: ECS Fargate containers (Frontend SPA and Backend Python)``` <br>
```. Data Tier: RDS PostgreSQL Multi-AZ + ElasticCache Redis cluster``` <br>

# *Key Feature Implementation:* 
```. Fault Tolerance through Multi-AZ RDS and ECS health checks``` <br>
```. Scalability via auto scalling policies based on CPU/Memories and requests.``` <br>
```. Security through VPC isolation and encryption comunication.``` <br>
```. Performance optimization with Redis caching and CloudFront CDN.``` <br>
```. Cost Optimization using Fargate serverless containers``` <br>

# Architecture diagram is created based in the AWS well architected framework, following the AWS best practices.   ---architecture_diagram.jpg



# *Docker*
```. Containerized frontend and backend for consistent deployment``` <br>
```. Dockerfiles optimized for smaller image sizes``` <br>
```. Images stored in ECR for secure and scalable registry``` <br>

# *S3 Storage*
```. Private S3 bucket with server-side encryption (AES-256)``` <br>
```. Versioning enabled for data protection``` <br>
```. Lifecycle policies for cost optimization``` <br>
```. IAM role-based access from ECS tasks``` <br>
```. Block all public access enabled``` <br>

# *Terraform*
```. Infrastructure as Code for reproducible deployments``` <br>
```. Modular design for reusability and maintainability``` <br>
```. State management with S3 backend and DynamoDB locking``` <br>
```. Automated provisioning of all AWS resources``` <br>

# *gitlab CI*
```. Automated build and push of Docker images to ECR``` <br>
```. Deployment pipeline triggering Terraform apply``` <br>


# Cost estimation is made based on the primary factors, i.e. ECS,ALB and RDS, other services are minor in terms of cost as they are either very low or usage basis (Route 53, CloudFront, CloudWatch, SNS, AWS SM).  ---cost_estimation.png


