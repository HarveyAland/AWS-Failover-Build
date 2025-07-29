## 🌐 Multi-Region AWS Failover Infrastructure (Disaster Recovery)

This project showcases a highly available, fault-tolerant, and disaster-resilient infrastructure in AWS. It implements automatic regional failover for the application layer using Route 53, EC2 Auto Scaling Groups with ALBs, and CloudWatch–driven failover automation — all built with Terraform. The RDS database is configured with Multi‑AZ failover within the primary region only, ensuring high availability at the data layer.

> **See the attached PDF** for a comprehensive breakdown, including detailed deployment steps, testing procedures, and screenshots of all key resources.

---

### 📌 Project Goals

- ✅ Ensure application‑level continuity with multi‑region failover  
- ✅ Maintain high availability for RDS using Multi‑AZ  
- ✅ Implement infrastructure as code with Terraform  
- ✅ Integrate monitoring, alerting, and failover testing  
- ✅ Design a real‑world, production‑grade solution to showcase advanced AWS cloud engineering skills  

---

### 🧱 Architecture Overview

| Component                                   | Primary Region (us-east-1) | Failover Region (us-west-2) |
|---------------------------------------------|:-------------------------:|:---------------------------:|
| VPC & Subnets                               | ✅                        | ✅                          |
| EC2 Auto Scaling (w/ ALB)                   | ✅                        | ✅                          |
| RDS (Multi-AZ)                              | ✅                        | –                           |
| AWS Backup Vault                            | –                         | ✅ (backups)                |
| Route 53 Health Checks & Failover Routing   | Receives traffic if primary fails | ✅                |
| CloudWatch Alarms                           | ✅                        | ✅                          |
| SNS Notifications                           | ✅                        | ✅                          |

> **Note:** RDS is not regionally replicated. It is configured for automatic failover within the primary region using the Multi‑AZ deployment option.

---

### ⚙️ Technologies Used

- **Terraform (IaC)**
- **AWS EC2, ALB, Auto Scaling Groups**
- **AWS RDS (Multi‑AZ only)**
- **AWS Backup**
- **AWS Route 53** (Failover Routing, Health Checks)
- **AWS CloudWatch + SNS** (Monitoring & Alerts)
- **AWS Lambda**

---

### 🔁 Failover Strategy

1. **Route 53 Health Checks** monitor the primary region’s ALB.  
2. On failure, failover routing automatically directs traffic to the standby region.  
3. **CloudWatch Alarms** detect EC2 or ALB issues and trigger SNS notifications.  
4. **SNS** topic is subscribed to a Lambda function which scales the failover region.  
5. **RDS** uses Multi‑AZ for automatic failover between Availability Zones within us-east-1.  

---

### 🔐 Security & Compliance

- IAM roles are restricted with **least‑privilege** policies.  
- **KMS** is used for backup encryption.  
- Resources are tagged for visibility and compliance (e.g., `Environment`, `Owner`, `CostCenter`).  
- Private subnets and NAT Gateways protect backend resources.  

---

### 🧪 Post-Deployment Testing

- ✅ Verified primary ALB & RDS accessibility from EC2 instances  
- ✅ Simulated ALB failure and validated Route 53 failover  
- ✅ Received alert emails via SNS for CloudWatch‑triggered events  
- ✅ Confirmed backups are copied to secondary region vault  
- ✅ Ensured DNS health checks transition appropriately  
- ✅ Verified RDS failover between Availability Zones  

---

### 📚 Lessons Learned

- Built expertise in **multi-region AWS architecture**.  
- Learned how to **monitor and route traffic** based on real‑time health.  
- Implemented **RDS Multi‑AZ failover** for database high availability within a single region.  

---

### 🏁 Status

- ✅ Completed and tested  
- 🧹 Resources have been torn down post-verification to avoid charges.  


---

### 🙌 Acknowledgements

Built as part of a personal initiative to demonstrate real‑world cloud engineering skills with a focus on **resilience**, **observability**, and **automation**.  

