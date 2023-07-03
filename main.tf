resource "aws_iam_policy" "policy" {
  name = "${var.component}-${var.env}-ssm-policy"
  path = "/"
  description = "${var.component}-${var.env}-ssm-policy"

  policy = jsonencode 
  {{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:124430735972:parameter/roboshop.${var.env}.${var.component}*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}}
}

resource "aws_iam_role" "test_role" {
  name = "${var.component}-${var.env}-ec2-role"

  assume_role_policy = josonencode{{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}}

}

resource "aws_security_group" "sg" {
  name        = "${var.env}-${var.component}-sg"
  description = "Allow TLS inbound traffic"


  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = {
    Name = "${var.env}-${var.component}-sg"
  }
}


resource "aws_instance" "ec2" {
   ami           = data.aws_ami.ami.id
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name = "${var.env}-${var.component}"
  }

}
