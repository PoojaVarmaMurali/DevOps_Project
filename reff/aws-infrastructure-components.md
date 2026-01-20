# AWS Infrastructure Components

## Core Services Configuration

### 1. Amazon ECS (Elastic Container Service)
```
ECS Cluster Configuration:
├── Cluster Name: web-app-cluster
├── Launch Type: Fargate (serverless containers)
├── Services:
│   ├── Frontend Service
│   │   ├── Task Definition: frontend-task
│   │   ├── Desired Count: 2 (minimum)
│   │   ├── Auto Scaling: 2-10 tasks
│   │   └── Health Check: /health endpoint
│   └── Backend Service
│       ├── Task Definition: backend-task
│       ├── Desired Count: 2 (minimum)
│       ├── Auto Scaling: 2-20 tasks
│       └── Health Check: /api/health endpoint
```

### 2. Application Load Balancer (ALB)
```
ALB Configuration:
├── Type: Application Load Balancer
├── Scheme: Internet-facing
├── Listeners:
│   ├── HTTPS:443 (Primary)
│   └── HTTP:80 (Redirect to HTTPS)
├── Target Groups:
│   ├── Frontend-TG (Port 3000)
│   └── Backend-TG (Port 8000)
└── Rules:
    ├── /api/* → Backend Target Group
    └── /* → Frontend Target Group
```

### 3. Amazon RDS
```
RDS Configuration:
├── Engine: PostgreSQL 14.x
├── Instance Class: db.r6g.large
├── Multi-AZ: Enabled
├── Storage:
│   ├── Type: gp3
│   ├── Size: 100 GB (initial)
│   └── Auto Scaling: Up to 1000 GB
├── Backup:
│   ├── Retention: 7 days
│   └── Automated Snapshots: Enabled
└── Security:
    ├── Encryption at Rest: Enabled
    └── VPC Security Groups: db-security-group
```

### 4. ElastiCache Redis
```
ElastiCache Configuration:
├── Engine: Redis 7.x
├── Node Type: cache.r6g.large
├── Cluster Mode: Enabled
├── Replication Groups: 2
├── Shards: 2
├── Replicas per Shard: 1
└── Security:
    ├── Encryption in Transit: Enabled
    ├── Encryption at Rest: Enabled
    └── Auth Token: Enabled
```

### 5. VPC Network Architecture
```
VPC Configuration:
├── CIDR Block: 10.0.0.0/16
├── Public Subnets:
│   ├── 10.0.1.0/24 (AZ-1a) - ALB, NAT Gateway
│   └── 10.0.2.0/24 (AZ-1b) - ALB, NAT Gateway
├── Private Subnets (App Tier):
│   ├── 10.0.10.0/24 (AZ-1a) - ECS Tasks
│   └── 10.0.11.0/24 (AZ-1b) - ECS Tasks
└── Private Subnets (Data Tier):
    ├── 10.0.20.0/24 (AZ-1a) - RDS, ElastiCache
    └── 10.0.21.0/24 (AZ-1b) - RDS, ElastiCache
```

## Security Groups

### ALB Security Group
```
Inbound Rules:
├── HTTP (80) from 0.0.0.0/0
├── HTTPS (443) from 0.0.0.0/0
Outbound Rules:
└── All traffic to ECS Security Group
```

### ECS Security Group
```
Inbound Rules:
├── Port 3000 from ALB Security Group (Frontend)
├── Port 8000 from ALB Security Group (Backend)
Outbound Rules:
├── HTTPS (443) to 0.0.0.0/0 (External APIs)
├── Port 5432 to DB Security Group (PostgreSQL)
└── Port 6379 to Cache Security Group (Redis)
```

### Database Security Group
```
Inbound Rules:
├── Port 5432 from ECS Security Group (PostgreSQL)
├── Port 6379 from ECS Security Group (Redis)
Outbound Rules:
└── None (Database tier doesn't initiate outbound)
```

## Auto Scaling Configuration

### ECS Service Auto Scaling
```
Frontend Service:
├── Min Capacity: 2 tasks
├── Max Capacity: 10 tasks
├── Target Tracking Policies:
│   ├── CPU Utilization: 70%
│   └── Memory Utilization: 80%

Backend Service:
├── Min Capacity: 2 tasks
├── Max Capacity: 20 tasks
├── Target Tracking Policies:
│   ├── CPU Utilization: 70%
│   ├── Memory Utilization: 80%
│   └── ALB Request Count: 1000 requests/target
```

## Monitoring & Alerting

### CloudWatch Metrics
```
Application Metrics:
├── ECS Service CPU/Memory Utilization
├── ALB Request Count & Response Time
├── RDS CPU, Memory, Connections
├── ElastiCache CPU, Memory, Hit Rate
└── Custom Application Metrics

Log Groups:
├── /ecs/frontend-service
├── /ecs/backend-service
├── /aws/rds/instance/web-app-db/postgresql
└── /aws/elasticache/redis
```

### SNS Topics & Alarms
```
Critical Alarms:
├── ECS Service Unhealthy Tasks
├── ALB High Response Time (>2s)
├── RDS High CPU (>80%)
├── RDS Low Free Storage (<20%)
└── ElastiCache High CPU (>80%)

Warning Alarms:
├── ECS Service High CPU (>70%)
├── ALB 4xx/5xx Error Rate (>5%)
└── RDS Connection Count (>80% max)
```

## Cost Optimization

### Reserved Instances & Savings Plans
- RDS Reserved Instances (1-year term)
- ElastiCache Reserved Nodes (1-year term)
- Compute Savings Plans for ECS Fargate

### Resource Right-Sizing
- CloudWatch Container Insights for ECS optimization
- RDS Performance Insights for database tuning
- Regular review of unused resources

## Disaster Recovery

### Backup Strategy
```
RDS Backups:
├── Automated Daily Snapshots (7-day retention)
├── Manual Snapshots (long-term retention)
└── Cross-Region Backup Replication

Application Backups:
├── ECS Task Definitions versioned
├── ALB Configuration in CloudFormation
└── Infrastructure as Code (Terraform/CDK)
```

### Recovery Procedures
- RDS Point-in-Time Recovery (up to 35 days)
- Cross-AZ failover (automatic)
- Cross-Region disaster recovery (manual)