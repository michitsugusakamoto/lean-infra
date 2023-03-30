#api
data "aws_iam_policy_document" "image" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::259798983143:role/ecsTaskExecutionRole"
      ]
    }
  }
}

resource "aws_ecr_repository" "api" {
  name = "${var.name}-api"

  force_delete = true
}

resource "aws_ecr_repository_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy     = data.aws_iam_policy_document.image.json
}

// 坂元追記
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "MyEcsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
// ここまで

#ui
resource "aws_ecr_repository" "ui" {
  name = "${var.name}-ui"

  force_delete = true
}

resource "aws_ecr_repository_policy" "ui" {
  repository = aws_ecr_repository.ui.name
  policy     = data.aws_iam_policy_document.image.json
}