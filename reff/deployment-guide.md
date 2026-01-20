# AWS ECS Deployment Guide

## Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed locally
- Terraform or AWS CDK (optional, for Infrastructure as Code)

## Step-by-Step Deployment

### Phase 1: Network Infrastructure

#### 1. Create VPC and Subnets
```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=web-app-vpc}]'

# Create Internet Gateway
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=web-app-igw}]'

# Create Public Subnets (2 AZs)
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b

# Create Private Subnets for Applications
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.10.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.11.0/24 --availability-zone us-east-1b

# Create Private Subnets for Database
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.20.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.21.0/24 --availability-zone us-east-1b
```

#### 2. Create NAT Gateways
```bash
# Allocate Elastic IPs
aws ec2 allocate-address --domain vpc

# Create NAT Gateways in each public subnet
aws ec2 create-nat-gateway --subnet-id subnet-xxx --allocation-id eipalloc-xxx
```

### Phase 2: Security Groups

#### 3. Create Security Groups
```bash
# ALB Security Group
aws ec2 create-security-group --group-name alb-sg --description "ALB Security Group" --vpc-id vpc-xxx

# ECS Security Group
aws ec2 create-security-group --group-name ecs-sg --description "ECS Security Group" --vpc-id vpc-xxx

# Database Security Group
aws ec2 create-security-group --group-name db-sg --description "Database Security Group" --vpc-id vpc-xxx
```

### Phase 3: Database Setup

#### 4. Create RDS Subnet Group
```bash
aws rds create-db-subnet-group \
    --db-subnet-group-name web-app-db-subnet-group \
    --db-subnet-group-description "Subnet group for web app database" \
    --subnet-ids subnet-xxx subnet-yyy
```

#### 5. Create RDS Instance
```bash
aws rds create-db-instance \
    --db-instance-identifier web-app-db \
    --db-instance-class db.r6g.large \
    --engine postgres \
    --engine-version 14.9 \
    --allocated-storage 100 \
    --storage-type gp3 \
    --storage-encrypted \
    --multi-az \
    --db-name webapp \
    --master-username dbadmin \
    --master-user-password "SecurePassword123!" \
    --db-subnet-group-name web-app-db-subnet-group \
    --vpc-security-group-ids sg-xxx \
    --backup-retention-period 7 \
    --deletion-protection
```

#### 6. Create ElastiCache Subnet Group and Cluster
```bash
# Create subnet group
aws elasticache create-cache-subnet-group \
    --cache-subnet-group-name web-app-cache-subnet-group \
    --cache-subnet-group-description "Subnet group for web app cache" \
    --subnet-ids subnet-xxx subnet-yyy

# Create Redis cluster
aws elasticache create-replication-group \
    --replication-group-id web-app-redis \
    --description "Redis cluster for web app" \
    --cache-node-type cache.r6g.large \
    --engine redis \
    --engine-version 7.0 \
    --num-cache-clusters 2 \
    --cache-subnet-group-name web-app-cache-subnet-group \
    --security-group-ids sg-xxx \
    --at-rest-encryption-enabled \
    --transit-encryption-enabled
```

### Phase 4: Container Registry

#### 7. Create ECR Repositories
```bash
# Create repository for backend
aws ecr create-repository --repository-name web-app/backend

# Create repository for frontend
aws ecr create-repository --repository-name web-app/frontend

# Get login token and login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

#### 8. Build and Push Docker Images
```bash
# Build and push backend image
docker build -t web-app/backend -f Backend.dockerfile .
docker tag web-app/backend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app/backend:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app/backend:latest

# Build and push frontend image (assuming you have a Frontend.dockerfile)
docker build -t web-app/frontend -f Frontend.dockerfile .
docker tag web-app/frontend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app/frontend:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app/frontend:latest
```

### Phase 5: ECS Setup

#### 9. Create ECS Cluster
```bash
aws ecs create-cluster --cluster-name web-app-cluster --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1
```

#### 10. Create Task Definitions
```bash
# Create backend task definition
aws ecs register-task-definition --cli-input-json file://backend-task-definition.json

# Create frontend task definition
aws ecs register-task-definition --cli-input-json file://frontend-task-definition.json
```

### Phase 6: Load Balancer

#### 11. Create Application Load Balancer
```bash
# Create ALB
aws elbv2 create-load-balancer \
    --name web-app-alb \
    --subnets subnet-xxx subnet-yyy \
    --security-groups sg-xxx \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4

# Create target groups
aws elbv2 create-target-group \
    --name frontend-tg \
    --protocol HTTP \
    --port 3000 \
    --vpc-id vpc-xxx \
    --target-type ip \
    --health-check-path /health

aws elbv2 create-target-group \
    --name backend-tg \
    --protocol HTTP \
    --port 8000 \
    --vpc-id vpc-xxx \
    --target-type ip \
    --health-check-path /api/health
```

#### 12. Create Listeners and Rules
```bash
# Create HTTPS listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/web-app-alb/xxx \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/xxx \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/frontend-tg/xxx

# Create rule for API traffic
aws elbv2 create-rule \
    --listener-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/web-app-alb/xxx/xxx \
    --priority 100 \
    --conditions Field=path-pattern,Values="/api/*" \
    --actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/backend-tg/xxx
```

### Phase 7: ECS Services

#### 13. Create ECS Services
```bash
# Create backend service
aws ecs create-service \
    --cluster web-app-cluster \
    --service-name backend-service \
    --task-definition backend-task:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
    --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/backend-tg/xxx,containerName=backend,containerPort=8000

# Create frontend service
aws ecs create-service \
    --cluster web-app-cluster \
    --service-name frontend-service \
    --task-definition frontend-task:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
    --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/frontend-tg/xxx,containerName=frontend,containerPort=3000
```

### Phase 8: Auto Scaling

#### 14. Configure Auto Scaling
```bash
# Register scalable targets
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/web-app-cluster/backend-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 20

# Create scaling policies
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/web-app-cluster/backend-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name backend-cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration file://cpu-scaling-policy.json
```

### Phase 9: Monitoring

#### 15. Create CloudWatch Alarms
```bash
# Create CPU utilization alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "ECS-Backend-HighCPU" \
    --alarm-description "Backend service high CPU utilization" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:123456789012:web-app-alerts
```

### Phase 10: DNS and CDN

#### 16. Configure Route 53 and CloudFront
```bash
# Create hosted zone (if using custom domain)
aws route53 create-hosted-zone --name example.com --caller-reference $(date +%s)

# Create CloudFront distribution
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

## Post-Deployment Verification

### Health Checks
1. Verify ALB target health: `aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...`
2. Check ECS service status: `aws ecs describe-services --cluster web-app-cluster --services backend-service frontend-service`
3. Test application endpoints through ALB DNS name
4. Verify database connectivity from ECS tasks

### Monitoring Setup
1. Configure CloudWatch dashboards
2. Set up SNS topics for alerts
3. Enable AWS X-Ray for distributed tracing
4. Configure log aggregation and retention policies

## Maintenance Tasks

### Regular Operations
- Monitor CloudWatch metrics and alarms
- Review and rotate secrets in AWS Secrets Manager
- Update ECS task definitions with new container images
- Perform RDS maintenance windows
- Review and optimize costs using AWS Cost Explorer

### Security Updates
- Regularly update base container images
- Review and update security group rules
- Rotate database passwords
- Update SSL certificates
- Perform security assessments