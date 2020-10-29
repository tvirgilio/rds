# Region
variable "region" {
  default =  "us-east-1"
}
# SGBD
variable "engine" {
  description = "The database engine"
  type = string
  default = "mysql"
}
# Tamanho
variable "allocated_storage" {
  description = "The amount of allocated storage."
  type = number
  default = 20
}
# Tipo de storage (ssd/gp2/sshd) 
variable "storage_type" {
  description = "type of the storage"
  type = string
  default = "gp2"
}
# Usuario
variable "username" {
  description = "Username for the master DB user."
  default = "wiki"
  type = string
}
# Senha
variable "password" {
  description = "password of the database"
  default = "wik987%$"
  type = string
}
# Tipo de Instancia
variable "instance_class" {
  description = "The RDS instance class"
  default = "db.t2.micro"
  type = string
}
# Versão
variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
  default = "default.mysql5.7"
  type = string
}
#versão do mysql
variable "engine_version" {
  description = "The engine version"
  default = "5.7"
  type = number
}
# pegar ultima versão de snapshot
variable "skip_final_snapshot" {
  description = "skip snapshot"
  default = "true"
  type = string
}
# indentificador
variable "identifier" {
  description = "The name of the RDS instance"
  default = "wikidatabase"
  type = string
}
# porta
variable "port" {
  description = "The port on which the DB accepts connections"
  default = "3306"
  type = number
}
# nome do banco 
variable "name" {
  description = "The database name"
  default = "wikidatabase"
  type = string
}


#########################################




#Zonas de Disponibilidade 
variable "azs" {
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

#Chave de Acesso
variable "key_name" {
  default = "terraform-aws"
}

# RHEL 8 / AMI
variable "aws_ami" {
  default="ami-098f16afa9edf40be"
}

# VPC and Subnet
variable "aws_cidr_vpc" {
  default = "10.0.0.0/16"
}

#Subnet Producao 1
variable "aws_cidr_subnet1" {
  default = "10.0.1.0/24"
}

#Subnet Producao 2
variable "aws_cidr_subnet2" {
  default = "10.0.2.0/24"
}

#Subnet Grafana
variable "aws_cidr_subnet3" {
  default = "10.0.3.0/24"
}

#Nome do Security Group
variable "aws_sg" {
  default = "sg_mediawiki"
}

#IP Privado
variable "ip_priv"{
  default = {
    "wiki01"  = "10.0.1.10"
    "wiki02"  = "10.0.2.20"
    "grafana" = "10.0.3.30"
  }
}

# CNAME dos servidores
variable "aws_tags" {
  type = "map"
  default = {
    "webserver1" = "MediaWiki-Web-1"
	  "webserver2" = "MediaWiki-Web-2"
    "grafana" = "Grafana" 
  }
}


variable "aws_instance_type" {
  default = "t2.micro"
}


