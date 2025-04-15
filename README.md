# ACS730 Final Project - Two-Tier Web Application Deployment (Terraform + Ansible)

## Team Members

- Sandeep Subedi
- Bishal Kumar Das
- Kushal Bhandari
- Ajay Singh

---

## Project Overview

This project automates the deployment of a two-tier web application using **Terraform** for infrastructure provisioning and **Ansible** for post-deployment configuration. The setup was executed and tested manually via **AWS Cloud9**.

---

## Prerequisites

Before starting, ensure the following are set up:

1. **AWS Account**: Access to AWS with permissions for EC2, VPC, S3, ALB, and Cloud9.
2. **AWS CLI**: Configured with valid credentials in your Cloud9 environment.
3. **Terraform**: Installed in the Cloud9 environment.
4. **Ansible**: Installed in the Cloud9 environment.
5. **S3 Bucket**:
   - Create an S3 bucket named `acs730-finalbucket`.
   - Upload the `demo.png` file to this bucket.

---

## Manual Deployment Instructions

### 1. Git Clone

Clone the project repository to your AWS Cloud9 environment:

```bash
git clone https://github.com/Sandeep1111able/FinalProject-ACS730.git
```

### 2. Terraform Steps (Run in Cloud9)

**Network Infrastructure:**

```bash
cd terraform/network
terraform init
terraform apply --auto-approve
```

**Webserver Infrastructure:**

```bash
cd ../webserver
ssh-keygen -t rsa -f group -N ""
terraform init
terraform plan
terraform apply --auto-approve
```

**SSH into EC2 Webservers via Bastion**

```bash
scp -i group group ec2-user@<bastion-public-ip>:/home/ec2-user/
```

**SSH into Bastion Host**

```bash
ssh -i group ec2-user@<bastion-public-ip>
chmod 400 group
```

**SSH into Database Server**

```bash
ssh -i group ec2-user@<database-private-ip>
```

**SSH into Another Private Webserver**

```bash
ssh -i group ec2-user@<webserver-private-ip>
```

**Ansible Configuration**

```bash
cd ansible
ansible-playbook playbook_getimage.yaml
ansible-playbook playbook_webservers.yaml -i aws_ec2.yaml
```

**Cleanup**

```bash
cd terraform/webserver
terraform destroy --auto-approve

cd ../network
terraform destroy --auto-approve
```
