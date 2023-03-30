resource "aws_security_group" "alb" {
    name    = "${var.name}-alb"
    vpc_id  = var.vpc_id

    ingress {
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "vpc_endpoint" {
    name    = "${var.name}-vpc-endpoint"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    egress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }
}

resource "aws_security_group" "ecs_task" {
    name   = "${var.name}-ecs-task"
    vpc_id = var.vpc_id

    ingress {
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
    }
    
    ingress {
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "rds" {
    name   = "${var.name}-rds"
    vpc_id = var.vpc_id

    ingress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        cidr_blocks     = [var.vpc_cidr]
        security_groups = [aws_security_group.ecs_task.id]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}