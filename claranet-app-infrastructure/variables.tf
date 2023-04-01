variable "region" {
  type = string
  default = "eu-central-1"
}

variable "alb_name" {
  type = string
  default = "phoenix-alb"
}

variable "tg_name" {
  type = string
  default = "phoenix-tg"
}

variable "alb_sg_name" {
  type = string
  default = "alb-http-sg"
}

variable "alb_sg_desc" {
  type = string
  default = "Allow HTTP inbound traffic"
}

variable "asg_name" {
  type = string
  default = "phoenix-asg"
}

variable "asg_policy" {
  type = string
  default = "asg-scaling-policy"
}

variable "lt_name" {
  type = string
  default = "phoenix-asg-lt"
}

variable "ec2_ami" {
  type = string
  default = "ami-08722fffad032e569"
}

variable "ec2_type" {
  type = string
  default = "t2.micro"
}

variable "lt_sg" {
  type = string
  default = "lt_sg"
}

variable "lt_sg_desc" {
  type = string
  default = "Allow HTTP inbound traffic from ALB"
}

variable "db_instance_id" {
  type = string
  default = "phoenix-db"
}

variable "db_cluster_id" {
  type = string
  default = "phoenix-db-cluster"
}

variable "db_subnet_grp_name" {
  type = string
  default = "phoenix-db-subnet-grp"
}

variable "master_dba" {
  type = string
  default = "phoenixdba"
}

variable "db_sg_name" {
  type = string
  default = "db-sg"
}

variable "cpu_percentage_th" {
  type = string
  default = "70"
  description = "Threshold for the CPU utilization percentage."
}

variable "missing_data_behavior" {
  type = string
  default = "breaching"
  description = "Behavior in case of missing data from the metric."
}

variable "sns_topic_name" {
  type = string
  default = "phoenix-alarms-sns"
}
#tflint-ignore: terraform_unused_declarations
variable "support_email" {
  type = string
  default = "devteam@devteamdomain.com"
}