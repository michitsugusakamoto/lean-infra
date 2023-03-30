// VPC本体
resource "aws_vpc" "default" {
    cidr_block          = var.cidr_block
    instance_tenancy     = "default"

    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = var.name
    }
}

// VPC とインターネットとの間の通信を可能にする VPC コンポーネント
resource "aws_internet_gateway" "default" {
    vpc_id = aws_vpc.default.id

    tags = {
        Name = var.name
    }
}

// パブリックサブネット
resource "aws_subnet" "public" {
    count                   = length(var.subnet_azs)
    vpc_id                  = aws_vpc.default.id
    cidr_block              = element(var.public_subnet_cidrs, count.index)
    availability_zone       = element(var.subnet_azs, count.index)
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.name}-public-${count.index}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.default.id
    
    tags = {
        Name = "${var.name}-public"
    }
}

resource "aws_route" "public_internet_gateway" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table_association" "public" {
    count          = length(var.subnet_azs)
    route_table_id = aws_route_table.public.id
    subnet_id      = element(aws_subnet.public.*.id, count.index)
}

// プライベートサブネット
resource "aws_subnet" "private" {
    count                   = length(var.subnet_azs)
    vpc_id                  = aws_vpc.default.id
    cidr_block              = element(var.private_subnet_cidrs, count.index)
    availability_zone       = element(var.subnet_azs, count.index)
    map_public_ip_on_launch = false

    tags = {
        Name = "${var.name}-private-${count.index}"
    }
}

resource "aws_route_table" "private" {
    count  = length(var.subnet_azs)
    vpc_id = aws_vpc.default.id

    tags = {
        Name = "${var.name}-private-${count.index}"
    }
}

resource "aws_route_table_association" "private" {
    count          = length(var.subnet_azs)
    route_table_id = element(aws_route_table.private.*.id, count.index)
    subnet_id      = element(aws_subnet.private.*.id, count.index)
}

# ecr
resource "aws_vpc_endpoint" "ecr-dkr" {
    vpc_id     = aws_vpc.default.id
    subnet_ids = aws_subnet.private.*.id

    service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
    vpc_endpoint_type   = "Interface"
    security_group_ids  = [var.vpc_endpoint_sg]
    private_dns_enabled = true

    tags = {
        Name = "${var.name}-ecr-dkr"
    }
}

resource "aws_vpc_endpoint" "ecr-api" {
    vpc_id     = aws_vpc.default.id
    subnet_ids = aws_subnet.private.*.id

    service_name         = "com.amazonaws.ap-northeast-1.ecr.api"
    vpc_endpoint_type   = "Interface"
    security_group_ids  = [var.vpc_endpoint_sg]
    private_dns_enabled = true

    tags = {
        name = "${var.name}-ecr-api"
    }
}

# s3
resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.default.id

    service_name      = "com.amazonaws.ap-northeast-1.s3"
    vpc_endpoint_type = "Gateway"

    tags = {
        Name = "${var.name}-s3"
    }
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
    count           = length(var.subnet_azs)
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
    route_table_id  = aws_route_table.private[count.index].id
}