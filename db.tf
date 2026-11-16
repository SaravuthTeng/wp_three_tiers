### aws rds resource connect to wordpress images
resource "aws_db_instance" "wordpress_db" {
  identifier             = "wordpress-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "wordpress_db"
  username               = "admin"
  password               = var.db_password
# reference to netowk.tf

  db_subnet_group_name   = aws_db_subnet_group.wp_db_subnet.name
  vpc_security_group_ids = [aws_security_group.isolate_sg.id]
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "wp_db_subnet" {
  name       = "wordpress-db-subnet"
  subnet_ids = [
    aws_subnet.isolated_subnet.id, # Replace with your isolated subnet labels from network.tf
    aws_subnet.isolated_subnet_az2.id # Replace with your isolated subnet labels from network.tf
  ]
}
