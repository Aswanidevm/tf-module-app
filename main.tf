resource "aws_iam_policy" "policy" {
  name = "${var.component}-${var.env}-ssm-policy"
  path = "/"
  description = "${var.component}-${var.env}-ssm-policy"

  policy = jsonencode ({
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
            "Resource": "arn:aws:ssm:us-east-1:124430735972:parameter/roboshop.${var.component}-${var.env}.*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
})
}

resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}-ec2-role"

  assume_role_policy = jsonencode ({
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
})

}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-ec2-role"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-sg"
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
    Name = "${var.component}-${var.env}-sg"
  }
}


resource "aws_instance" "ec2" {
   ami           = data.aws_ami.ami.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = "${var.component}-${var.env}"
  }

}

resource "aws_route53_record" "dns" {
  zone_id = "Z04818282BOE8RVGV13K7"
  name    = "${var.component}.myprojecdevops.info"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.ec2.private_ip]
}

resource "null_resource" "ansible"{
  depends_on = [ aws_instance.ec2, aws_route53_record.dns]
  provisioner "remote-exec" {

  connection {
    type     = "ssh"
    user     = "centos"
    password = "DevOps321"
    host     = aws_instance.ec2.public_ip
  }

  
    inline = [
     "sudo labauto ansible",
     "sudo set-hostname -skip-apply ${var.component}",
     "ansible-pull -i localhost, -U https://github.com/Aswanidevm/roboshop-ansible1.git main.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}