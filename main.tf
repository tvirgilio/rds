# Cloud Provider Access

provider "aws" {
 region     = "${var.region}"
}

# Setting up VPC
resource "aws_vpc" "mw_vpc" {
  cidr_block = "${var.aws_cidr_vpc}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MediaWikiVPC"
  }
}

# Gateway para Internet 
resource "aws_internet_gateway" "mw_igw" {
    vpc_id = "${aws_vpc.mw_vpc.id}"
    tags = {
        Name = "Gateway para internet"
    }
}

#Tabela da rota de acesso a internet

resource "aws_route_table" "mw_rt" {
  vpc_id = "${aws_vpc.mw_vpc.id}"
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.mw_igw.id}"
    }

    tags = {
      Name = "Rota-MediaWiki"
    }
}

resource "aws_route_table_association" "PublicAZA" {
    subnet_id = "${aws_subnet.mw_subnet1.id}"
    route_table_id = "${aws_route_table.mw_rt.id}"
}

resource "aws_route_table_association" "PublicAZB" {
    subnet_id = "${aws_subnet.mw_subnet2.id}"
    route_table_id = "${aws_route_table.mw_rt.id}"
}

resource "aws_route_table_association" "PublicA_GF" {
    subnet_id = "${aws_subnet.mw_subnet3.id}"
    route_table_id = "${aws_route_table.mw_rt.id}"
}

# subnet1 - us-east-1a
resource "aws_subnet" "mw_subnet1" {
  vpc_id = "${aws_vpc.mw_vpc.id}"
  cidr_block = "${var.aws_cidr_subnet1}"
  availability_zone = "${element(var.azs, 0)}"
  tags = {
    Name = "MediaWikiSubnet1"
  }
}

# subnet2 - us-east-1b
resource "aws_subnet" "mw_subnet2" {
  vpc_id = "${aws_vpc.mw_vpc.id}"
  cidr_block = "${var.aws_cidr_subnet2}"
  availability_zone = "${element(var.azs, 1)}"
  tags = {
    Name = "MediaWikiSubnet2"
  }
}

# subnet3 - us-east-1c
resource "aws_subnet" "mw_subnet3" {
  vpc_id = "${aws_vpc.mw_vpc.id}"
  cidr_block = "${var.aws_cidr_subnet3}"
  availability_zone = "${element(var.azs, 2)}"
  tags = {
    Name = "MediaWikiSubnet3"
  }
}

#Criando security group
resource "aws_security_group" "mw_sg" {
  name = "mw_sg"
  description = "HTTP, SSH, BANCO e GRAFANA"
  vpc_id = "${aws_vpc.mw_vpc.id}"

#Liberar porta 22 "SSH"
  ingress {
    from_port = 22 
    to_port  = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

#Liberar porta 80  "HTTP"
   ingress {
    from_port = 80
    to_port  = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

#Liberar porta 3306 "BANCO"
  ingress {
    from_port = 3306
    to_port  = 3306
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

#Liberar porta 3000 "Grafana"
  ingress {
  from_port = 3000
  to_port = 3000
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  }

#Liberar porta 5000 "API-REST"
  ingress {
  from_port = 5000
  to_port = 5000
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  }

#Liberar ICMP  
  ingress {
    from_port = "0"
    to_port  = "0"
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#Saida
  egress {
    from_port = "0"
    to_port  = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Instancias

# webserver1
resource "aws_instance" "webserver1" {
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_instance_type}"
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.mw_sg.id}"]
  subnet_id     = "${aws_subnet.mw_subnet1.id}" 
  private_ip = lookup(var.ip_priv,"wiki01")
  associate_public_ip_address = true
  tags = {
    Name = "${lookup(var.aws_tags,"webserver1")}"
    group = "web"
  }
}

# webserver2
resource "aws_instance" "webserver2" {
  depends_on = [aws_security_group.mw_sg]
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_instance_type}"
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.mw_sg.id}"]
  subnet_id     = "${aws_subnet.mw_subnet2.id}" 
  private_ip = lookup(var.ip_priv,"wiki02")
  associate_public_ip_address = true
  tags = {
    Name = "${lookup(var.aws_tags,"webserver2")}"
    group = "web"
  }
}

# GRAFANA
resource "aws_instance" "grafana" {
  depends_on = [aws_security_group.mw_sg]
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_instance_type}"
  key_name = var.key_name 
  vpc_security_group_ids = ["${aws_security_group.mw_sg.id}"]
  subnet_id     = "${aws_subnet.mw_subnet3.id}"
  private_ip = lookup(var.ip_priv,"grafana")
  associate_public_ip_address = true
  
  tags = {
    Name = "${lookup(var.aws_tags,"grafana")}"
    group = "grafana"
  }
}

resource "aws_db_subnet_group" "bd" {
  name       = "rds"

  subnet_ids = [
    aws_subnet.mw_subnet1.id,
    aws_subnet.mw_subnet2.id,
    aws_subnet.mw_subnet3.id
  ]
  tags = {
    Name = "RDS"
  }
}

# Criando RDS
resource "aws_db_instance" "wikidatabase" {
  allocated_storage = var.allocated_storage
  storage_type = var.storage_type
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  name = var.name
  username = var.username
  password = var.password
  port = var.port
  identifier = var.identifier
  parameter_group_name = var.parameter_group_name
  skip_final_snapshot = var.skip_final_snapshot
  vpc_security_group_ids = ["${aws_security_group.mw_sg.id}"]
  db_subnet_group_name = aws_db_subnet_group.bd.name 
  publicly_accessible = true
  tags = {
    group = "wikidatabase"
  }

}

# Criando DNS
resource "aws_route53_zone" "primary" {
  name = "maven-wikimedia.tk"
}

# CNAME
resource "aws_route53_record" "wikidatabase-record" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "mediawiki.maven-wikimedia.tk"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.wikidatabase.address}"]
}


# ELB
resource "aws_elb" "mw_elb" {
  name = "MediaWikiELB"
  subnets         = ["${aws_subnet.mw_subnet1.id}", "${aws_subnet.mw_subnet2.id}"]
  security_groups = ["${aws_security_group.mw_sg.id}"]
  instances = ["${aws_instance.webserver1.id}", "${aws_instance.webserver2.id}"]
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
}

# endereço ELB
output "address" {
  value = "${aws_elb.mw_elb.dns_name}"
}