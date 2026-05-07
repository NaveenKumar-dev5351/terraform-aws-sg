# 🔒 Terraform AWS Security Group Module

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

## 🎯 Overview
Reusable Terraform module for creating AWS Security Groups
with consistent naming, tagging, and default egress rules.
Ingress rules are managed separately using
aws_security_group_rule to avoid circular dependencies
between security groups.

## 🏗️ Resources Created
- AWS Security Group with dynamic naming
- Default egress rule — allow all outbound traffic
- Consistent resource tagging using merge()

## 💡 Design Decision — Why No Ingress in Module?
Ingress rules are intentionally separated from the
Security Group resource to avoid circular dependency
issues. For example — when App SG needs to reference
DB SG and DB SG needs to reference App SG simultaneously,
keeping them separate prevents Terraform dependency
cycles.

## 📋 Input Variables

| Variable | Description | Type | Required |
|---|---|---|---|
| `project` | Project name | string | ✅ Yes |
| `environment` | Environment (dev/prod) | string | ✅ Yes |
| `sg_name` | Security group name suffix | string | ✅ Yes |
| `sg_description` | Security group description | string | ✅ Yes |
| `vpc_id` | VPC ID to create SG in | string | ✅ Yes |
| `sg_tags` | Additional tags | map(string) | ❌ No |

## 📤 Output Values

| Output | Description |
|---|---|
| `sg_id` | Security Group ID |
| `sg_arn` | Security Group ARN |
| `sg_name` | Security Group name |

## 🚀 Example Usage

```hcl
# Create Security Group
module "frontend_sg" {
  source = "git::https://github.com/NaveenKumar-dev5351/terraform-aws-sg.git"

  project        = "roboshop"
  environment    = "dev"
  sg_name        = "frontend"
  sg_description = "Security group for Roboshop frontend"
  vpc_id         = module.vpc.vpc_id
}

# Add ingress rules separately
resource "aws_security_group_rule" "frontend_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend_sg.sg_id
}

resource "aws_security_group_rule" "frontend_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend_sg.sg_id
}

# Reference SG in EC2 instance
module "frontend_instance" {
  source = "../terraform-aws-instance"
  sg_ids = [module.frontend_sg.sg_id]
}
```

## 🔗 Security Group Chaining Pattern

Instead of using CIDR blocks, this project uses
SG-to-SG referencing for zero-trust networking:

```hcl
# ✅ CORRECT — SG to SG reference
resource "aws_security_group_rule" "backend_alb_vpn" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.vpn.sg_id      # Only VPN can access
  security_group_id        = module.backend_alb.sg_id
}

# ❌ AVOID — CIDR based (less secure)
resource "aws_security_group_rule" "bad_example" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]   # Too broad
  security_group_id = module.backend_alb.sg_id
}
```

### Benefits of SG Chaining
- ✅ Zero-trust — only specific services communicate
- ✅ No hardcoded IPs — fully dynamic
- ✅ Scales automatically as instances change
- ✅ Prevents lateral movement attacks

## 🔒 Security Groups Created in Roboshop

| Component | Port | Source |
|---|---|---|
| Frontend | 80, 443 | 0.0.0.0/0 |
| Catalogue | 8080 | Backend ALB SG |
| User | 8080 | Backend ALB SG |
| Cart | 8080 | Backend ALB SG |
| Payment | 8080 | Backend ALB SG |
| Shipping | 8080 | Backend ALB SG |
| MongoDB | 27017 | App SGs only |
| MySQL | 3306 | App SGs only |
| Redis | 6379 | App SGs only |
| RabbitMQ | 5672 | App SGs only |
| Bastion | 22 | Trusted IPs |
| VPN | 1194 | 0.0.0.0/0 |

## ✅ Features
- ✅ Dynamic naming convention
- ✅ Consistent tagging using merge()
- ✅ Separated ingress rules pattern
- ✅ Default allow-all egress
- ✅ IPv4 and IPv6 egress support
- ✅ Circular dependency prevention

## 👨‍💻 Author
**Naveen Kumar Lingampelly**
DevOps Engineer | [LinkedIn](https://linkedin.com/in/naveenlingampelli)

## 🔗 Security Group Chaining Pattern

Instead of using CIDR blocks, this project uses
SG-to-SG referencing for zero-trust networking:

```hcl
# ✅ CORRECT — SG to SG reference
resource "aws_security_group_rule" "backend_alb_vpn" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.vpn.sg_id      # Only VPN can access
  security_group_id        = module.backend_alb.sg_id
}

# ❌ AVOID — CIDR based (less secure)
resource "aws_security_group_rule" "bad_example" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]   # Too broad
  security_group_id = module.backend_alb.sg_id
}
```

### Benefits of SG Chaining
- ✅ Zero-trust — only specific services communicate
- ✅ No hardcoded IPs — fully dynamic
- ✅ Scales automatically as instances change
- ✅ Prevents lateral movement attacks