# 1. Fetch Existing VPC and Subnet (Replace with actual IDs)
data "aws_vpc" "existing_vpc" {
  id = "vpc-02a88d80ac334f702"  # Replace with your existing VPC ID
}

data "aws_subnet" "existing_subnet" {
  id = "subnet-02340127e4267789d"  # Replace with your existing public subnet ID
}

# 2. Create Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH and outbound internet access"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Allow SSH from PowerShell (Use your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP
  }

  # Allow all outbound traffic (for HTTPS access)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Create IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 4. Create IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "DynamoDBAccessPolicy"
  description = "Allows EC2 instances to access DynamoDB"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "dynamodb:ListTables",  # ✅ Added this permission
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Resource = "arn:aws:dynamodb:us-east-1:255945442255:table/*"  # Make sure this is correct
    }]
  })
}


# 5. Attach IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

# 6. Create IAM Instance Profile (Needed for EC2 to use IAM Role)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# 7. Create EC2 Instance
resource "aws_instance" "ec2_instance" {
  ami             = "ami-085ad6ae776d8f09c"  # Change to latest Amazon Linux or Ubuntu AMI
  instance_type   = "t2.micro"
  subnet_id            = data.aws_subnet.existing_subnet.id
  associate_public_ip_address = true
  key_name                    = "agusjuli-key-pair" #Change to your keyname, e.g. jazeel-key-pair
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  # Corrected to reference VPC-based SG
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "agusjuli-ec2-dynamodb"
  }
}