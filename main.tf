module "network" {
  source      = "git@github.com:irgashevsardor/aws-infrastructure-terraform.git"
  vpc_cidr    = "10.0.0.0/16"
  region      = "us-east-1"
  environment = "dev"
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [module.network.vpc_id]
  }
}


resource "aws_iam_role" "eks_iam_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachement" {
  role       = aws_iam_role.eks_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

resource "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name

  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [for subnet_id in data.aws_subnets.all.ids : subnet_id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy_attachement]

}
