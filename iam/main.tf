// ecsTaskExecutionRole
data "aws_iam_policy_document" "ecs_task_exec_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_role_assume_role_policy.json

  inline_policy {
    name = "ReadSecret"

    policy = jsonencode({
      "Version"   = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "secretsmanager:GetSecretValue"
          ],
          "Resource" = [
            "*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "BucketAccess"

    policy = jsonencode({
      "Version"   = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetObject"
          ],
          "Resource" = [
            "arn:aws:s3:::${var.name}-images/*",
            "arn:aws:s3:::${var.name}-csv-error/*"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


// ecsEventsRole
data "aws_iam_policy_document" "ecs_events_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_events_role" {
  name               = "ecsEventsRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_events_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_events_role_policy" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}


// github actions
data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "AWS"
      identifiers = [
        // ステージング環境を落とす際の古いスナップショットを削除する処理で使用
        "arn:aws:iam::${var.aws_account_id_prd}:user/terraform",
        "arn:aws:iam::${var.aws_account_id_prd}:user/github-actions"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name = "JuchuHackGithubActions"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json

  inline_policy {
    name   = "JuchuHackPushContainer"
    policy = jsonencode(
      {
        "Version"   = "2012-10-17",
        "Statement" = [
          {
            "Sid"    = "GetAuthorizationToken",
            "Effect" = "Allow",
            "Action" = [
              "ecr:GetAuthorizationToken"
            ],
            "Resource" = "*"
          },
          {
            "Sid"    = "PushImageOnly",
            "Effect" = "Allow",
            "Action" = [
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:BatchCheckLayerAvailability",
              "ecr:PutImage",
              "ecr:InitiateLayerUpload",
              "ecr:UploadLayerPart",
              "ecr:CompleteLayerUpload"
            ],
            "Resource" = [
              "arn:aws:ecr:ap-northeast-1:259798983143:repository/sakamoto-learn-ui",
              "arn:aws:ecr:ap-northeast-1:259798983143:repository/sakamoto-learn-api",
              "arn:aws:ecr:ap-northeast-1:259798983143:repository/sakamoto-learn-closing"
            ]
          },
        ],
      }
    )
  }

  inline_policy {
    name   = "JuchuHackUpdateECSService"
    policy = jsonencode(
      {
        "Version"   = "2012-10-17",
        "Statement" = [
          {
            "Sid"    = "RegisterTaskDefinition",
            "Effect" = "Allow",
            "Action" = [
              "ecs:RegisterTaskDefinition"
            ],
            "Resource" = "*"
          },
          {
            "Sid"    = "UpdateService",
            "Effect" = "Allow",
            "Action" = [
              "ecs:UpdateServicePrimaryTaskSet",
              "ecs:DescribeServices",
              "ecs:UpdateService"
            ],
            "Resource" = [
              "arn:aws:ecs:ap-northeast-1:${var.aws_account_id}:service/${var.name}/ui",
              "arn:aws:ecs:ap-northeast-1:${var.aws_account_id}:service/${var.name}/api",
            ]
          },
          {
            "Effect"    = "Allow",
            "Action"    = "iam:PassRole",
            "Resource"  = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole",
            "Condition" = {
              "StringLike" = {
                "iam:PassedToService" = "ecs-tasks.amazonaws.com"
              }
            }
          }
        ],
      }
    )
  }

  inline_policy {
    name = "JuchuHackUpdateScheduledTask"

    policy = jsonencode({
      "Version"   = "2012-10-17",
      "Statement" = [
        {
          "Action" = [
            "ecs:RegisterTaskDefinition"
          ],
          "Effect"   = "Allow",
          "Resource" = "*",
          "Sid"      = "RegisterTaskDefinition"
        },
        {
          "Action" = [
            "events:ListRules",
            "events:ListTargetsByRule"
          ],
          "Effect"   = "Allow",
          "Resource" = "*",
          "Sid"      = "ListRulesAndTargets"
        },
        {
          "Action" = [
            "events:PutTargets"
          ],
          "Effect"   = "Allow",
          "Resource" = "arn:aws:events:ap-northeast-1:${var.aws_account_id}:rule/${var.name}-closing",
          "Sid"      = "PutTargets"
        },
        {
          "Action" = [
            "iam:PassRole"
          ],
          "Effect"   = "Allow",
          "Resource" = [
            "arn:aws:iam::${var.aws_account_id}:role/ecsEventsRole",
            "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
          ],
          "Sid" = "PassRolesInTaskDefinition"
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.env == "stg" ? [true] : []

    content {
      name = "JuchuHackHotfix"

      policy = jsonencode({
        "Version"   = "2012-10-17",
        "Statement" = [
          {
            "Action" = [
              "cloudformation:CreateStack",
              "cloudformation:DescribeStacks",
              "cloudformation:UpdateStack",
              "cloudformation:DeleteStack"
            ],
            "Effect"   = "Allow",
            "Resource" = "arn:aws:cloudformation:ap-northeast-1:${var.aws_account_id}:stack/hotfix-*",
          },
          {
            "Action" = [
              "elasticloadbalancing:CreateTargetGroup",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:ModifyTargetGroupAttributes",
              "elasticloadbalancing:DeleteTargetGroup",
              "elasticloadbalancing:DescribeRules",
              "elasticloadbalancing:CreateRule",
              "elasticloadbalancing:DeleteRule",
              "elasticloadbalancing:AddListenerCertificates",
              "elasticloadbalancing:RemoveListenerCertificates"
            ],
            "Effect"   = "Allow",
            "Resource" = "*",
          },
          {
            "Action" = [
              "route53:GetHostedZone",
              "route53:ChangeResourceRecordSets",
              "route53:GetChange",
              "route53:ListResourceRecordSets",
            ],
            "Effect"   = "Allow",
            "Resource" = "*",
          },
          {
            "Action" = [
              "logs:CreateLogGroup",
              "logs:DeleteLogGroup",
            ],
            "Effect"   = "Allow",
            "Resource" = "*",
          },
          {
            "Action" = [
              "ecs:DeregisterTaskDefinition",
              "ecs:CreateService",
              "ecs:DescribeServices",
              "ecs:UpdateService",
              "ecs:DeleteService",
            ],
            "Effect"   = "Allow",
            "Resource" = "*",
          },
          {
            "Action" = [
              "acm:RequestCertificate",
              "acm:DescribeCertificate",
              "acm:DeleteCertificate"
            ],
            "Effect"   = "Allow",
            "Resource" = "*",
          },
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.env == "stg" ? [true] : []

    content {
      name = "JuchuHackDescribeDBClusterSnapshots"

      policy = jsonencode({
        "Version"   = "2012-10-17",
        "Statement" = [
          {
            "Action"   = "rds:DescribeDBClusterSnapshots",
            "Effect"   = "Allow",
            "Resource" = "arn:aws:rds:ap-northeast-1:${var.aws_account_id}:cluster:${var.name}",
          },
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.env == "stg" ? [true] : []

    content {
      name = "JuchuHackDeleteDBClusterSnapshot"

      policy = jsonencode({
        "Version"   = "2012-10-17",
        "Statement" = [
          {
            "Action"   = "rds:DeleteDBClusterSnapshot",
            "Effect"   = "Allow",
            "Resource" = "arn:aws:rds:ap-northeast-1:${var.aws_account_id}:cluster-snapshot:${var.name}-*",
          },
        ]
      })
    }
  }
}

resource "aws_iam_role" "vpc_flow_log" {
  name               = "VpcFlowLog"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name   = "VpcFlowLog"
  role   = aws_iam_role.vpc_flow_log.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
