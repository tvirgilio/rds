# Cloud Provider Access
provider "aws" {
  profile = "pessoal-profile"
  region  = "ap-northeast-1"
}

# Setting up VPC
resource "aws_vpc" "mw_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MediaWikiVPC"
  }
}

# Gateway for Internet connection
resource "aws_internet_gateway" "mw_igw" {
  vpc_id = aws_vpc.mw_vpc.id
  tags = {
    Name = "Gateway para internet"
  }
}

# Creation Route Tables
resource "aws_route_table" "mw_rt" {
  vpc_id = aws_vpc.mw_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mw_igw.id
  }
    tags = {
      Name = "Rota-MediaWiki"
    }
}

# Routing Tables Associations
resource "aws_route_table_association" "public-az1" {
  subnet_id      = aws_subnet.mw_subnet1.id
  route_table_id = aws_route_table.mw_rt.id
}

resource "aws_route_table_association" "public-az2" {
  subnet_id      = aws_subnet.mw_subnet2.id
  route_table_id = aws_route_table.mw_rt.id
}

resource "aws_route_table_association" "public-az3" {
  subnet_id      = aws_subnet.mw_subnet3.id
  route_table_id = aws_route_table.mw_rt.id
}

# subnet1 - ap-northeast-1a
resource "aws_subnet" "mw_subnet1" {
  vpc_id            = aws_vpc.mw_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "MediaWikiSubnet1"
  }
}

# subnet2 - ap-northeast-1b
resource "aws_subnet" "mw_subnet2" {
  vpc_id            = aws_vpc.mw_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "MediaWikiSubnet2"
  }
}

# Subnet3 - ap-northeast-1c
resource "aws_subnet" "mw_subnet3" {
  vpc_id            = aws_vpc.mw_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "MediaWikiSubnet3"
  }
}

#Creation Security Group mw_sg
resource "aws_security_group" "mw_sg" {
  name        = "mw_sg"
  description = "Connection http, ssh, mysql, api-rest wiki and Grafana"
  vpc_id      = aws_vpc.mw_vpc.id
  tags = {
    "Name" = "mw_sg"
  }

# ingress port 22/ssh
  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ingress port 80/http
   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ingress port 3306 for mysql
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ingress port 3000 for grafana Connection
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ingress port 5000 for Connection api-rest (docker app)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ICMP ingress
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# egress for All Connections
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating ElasticLoadBalancer 
resource "aws_elb" "mw_elb" {
  name              = "media-terraform-elb"
  subnets           = ["${aws_subnet.mw_subnet1.id}", "${aws_subnet.mw_subnet2.id}"]
  security_groups   = ["${aws_security_group.mw_sg.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 5000
    lb_protocol       = "http"
  }
  instances       = ["${aws_instance.webserver1.id}", "${aws_instance.webserver2.id}"]
  tags = {
    Name = "media-terraform-elb"
  }
}

#Creation of EC2 instances for mediawiki Application
# App webserver1 Instance
resource "aws_instance" "webserver1" {
  security_groups             = [aws_security_group.mw_sg.id]
  ami                         = "ami-07dd14faa8a17fb3e"
  instance_type               = "t2.micro"
  key_name                    = "terraform-aws"
  subnet_id                   = aws_subnet.mw_subnet1.id
  private_ip                  = "10.0.1.10"
  associate_public_ip_address = true
  tags = {
    Name  = "mediawiki-web1"
    group = "web"
    app   = "Application"
  }
}

# App webserver2 Instance
resource "aws_instance" "webserver2" {
  security_groups             = [aws_security_group.mw_sg.id]
  ami                         = "ami-07dd14faa8a17fb3e"
  instance_type               = "t2.micro"
  key_name                    = "terraform-aws"
  subnet_id                   = aws_subnet.mw_subnet2.id
  private_ip                  = "10.0.2.20"
  associate_public_ip_address = true
  tags = {
    Name  = "mediawiki-web2"
    group = "web"
    app   = "Application"
  }
}

# Grafana Instance (Monitoring)
resource "aws_instance" "grafana" {
  security_groups             = [aws_security_group.mw_sg.id]
  ami                         = "ami-07dd14faa8a17fb3e"
  instance_type               = "t2.micro"
  key_name                    = "terraform-aws"
  subnet_id                   = aws_subnet.mw_subnet3.id
  private_ip                  = "10.0.3.30"
  associate_public_ip_address = true
  tags = {
    Name  = "mediawiki-grafana"
    group = "web"
    app   = "Monitoring"
  }
}

# Creating Subnet aws_db and associating application subnets
resource "aws_db_subnet_group" "bd" {
  name        = "rds"
  description = "Private subnets for RDS instance"
  subnet_ids  = [aws_subnet.mw_subnet1.id, aws_subnet.mw_subnet2.id, aws_subnet.mw_subnet3.id]
  tags = {
    Name = "My DB subnet group"
  }
}

# Security Group for DB Instance
resource "aws_security_group" "security-group-rds" {
    name        = "security-group-rds"
    description = "RDS security group"
    vpc_id      = aws_vpc.mw_vpc.id
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.mw_vpc.cidr_block]
   }
    ingress {
      from_port   = 3306
      to_port     = 3306
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "security-group-rds"
  }
}

# Creating RDS Instance
resource "aws_db_instance" "wikidatabase" {
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  name                    = "wikidatabase"
  username                = "wiki"
  password                = "wik987%$"
  port                    = 3306
  identifier              = "wikidatabase"
  parameter_group_name    = "default.mysql5.7"
  skip_final_snapshot     = true
  publicly_accessible     = true
  copy_tags_to_snapshot   = true
  maintenance_window      = "Mon:06:00-Mon:09:00"
  backup_window           = "09:01-11:00"
  backup_retention_period = 7
  db_subnet_group_name    = aws_db_subnet_group.bd.id
  vpc_security_group_ids  = [aws_security_group.security-group-rds.id]
  tags = {
    name        = "wikidatabase"
    application = "production"
  }
}

# Creating Replica RDS in ap-northeast-1d
resource "aws_db_instance" "wikidatabase-replica" {
  identifier              = "wikidatabase-replica"
  replicate_source_db     = aws_db_instance.wikidatabase.id
  availability_zone       = "ap-northeast-1d"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  username                = "wiki"
  password                = "wik987%$"
  port                    = 3306
  parameter_group_name    = "default.mysql5.7"
  maintenance_window      = "Mon:06:00-Mon:09:00"
  backup_window           = "09:01-11:00"
  backup_retention_period = 0
  skip_final_snapshot     = true
  publicly_accessible     = true
  copy_tags_to_snapshot   = true
  multi_az                = false
  apply_immediately       = true
  tags = {
    name        = "wikidatabase-replica"
    application = "production"
  }
}

# DNS zone creation (my-area)
resource "aws_route53_zone" "area-zone" {
  name = "applicationdesktop.cf"
}

# IP assignment of RDS Endpoint with CNAME
resource "aws_route53_record" "database-record" {
  zone_id = aws_route53_zone.my-area.zone_id
  name    = "database.applicationdesktop.cf"
  type    = "CNAME"
  ttl     = 30
  records = ["${aws_db_instance.wikidatabase.address}"]
}

# ElasticLoadBalancer Addres for Connections
output "address" {
  value = aws_elb.mw_elb.dns_name
}