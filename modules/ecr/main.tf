# Create ECR Repository 
resource "aws_ecr_repository" "main" {
  name                 = "${var.app_name}-repository-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Create ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}