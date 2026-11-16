# ==========================================
# 1. VPC & INTERNET GATEWAY
# ==========================================
resource "aws_vpc" "vpc_three_tier" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc-three-tier"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_three_tier.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# ==========================================
# 2. SUBNETS 3 Tiers = 3 Subnets
# ==========================================

# Public Subnets (Load Balancer / NAT Gateways)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_three_tier.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# Private Subnets (WordPress Application Tier)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_three_tier.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11)

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# Isolated Subnets (RDS / Aurora Database Tier)
resource "aws_subnet" "isolated_subnet" {
  vpc_id            = aws_vpc.vpc_three_tier.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 21)
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.environment}-isolated-subnet"
  }
}
resource "aws_subnet" "isolated_subnet_az2" {
  vpc_id            = aws_vpc.vpc_three_tier.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 22)
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.environment}-isolated-subnet"
  }
}
# ==========================================
# 3. NAT GATEWAYS & ROUTE TABLES
# ==========================================

# Public Route Table -> Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_three_tier.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IPs & NAT Gateways 1 only
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-nat-gw"
  }
}

# Private Route Tables -> NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_three_tier.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Isolated Route Table (No Internet or NAT access)
resource "aws_route_table" "isolated_rt" {
  vpc_id = aws_vpc.vpc_three_tier.id

  tags = {
    Name = "${var.environment}-isolated-rt"
  }
}

resource "aws_route_table_association" "isolated_assoc" {
  subnet_id      = aws_subnet.isolated_subnet.id
  route_table_id = aws_route_table.isolated_rt.id
}

# ==========================================
# 4. THREE-TIER SECURITY GROUPS
# ==========================================

### Tier 1: Public Load Balancer SG
resource "aws_security_group" "public_sg" {
  name        = "${var.environment}-first-tier-sg"
  vpc_id      = aws_vpc.vpc_three_tier.id
  description = "Allow HTTP and HTTPS traffic from the internet"

  tags = {
    Name = "${var.environment}-public-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "public_https" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_to_private" {
  security_group_id            = aws_security_group.public_sg.id
  referenced_security_group_id = aws_security_group.private_sg.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

### Tier 2: Private WordPress App SG
resource "aws_security_group" "private_sg" {
  name        = "${var.environment}-second-tier-sg"
  vpc_id      = aws_vpc.vpc_three_tier.id
  description = "Allow traffic only from public_sg"

  tags = {
    Name = "${var.environment}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_from_public" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "private_outbound" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

### Tier 3: Isolated Database SG (RDS / Aurora)
resource "aws_security_group" "isolate_sg" {
  name        = "${var.environment}-third-tier-sg"
  vpc_id      = aws_vpc.vpc_three_tier.id
  description = "Allow MySQL traffic only from private_sg"

  tags = {
    Name = "${var.environment}-isolate-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "isolate_from_private" {
  security_group_id            = aws_security_group.isolate_sg.id
  referenced_security_group_id = aws_security_group.private_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

