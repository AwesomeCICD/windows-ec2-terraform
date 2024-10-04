
locals {
  win_runner_token = jsondecode(data.aws_secretsmanager_secret_version.windows_ec2_runner_token_version.secret_string)["cci_win_ec2_runner_token"]
}


data "template_file" "user_data_ec2_windows" {
  template = file("${path.module}/templates/user_data_ec2_windows.ps1")

  vars = {
    win_runner_token       = local.win_runner_token
    circle_server_endpoint = var.circle_server_endpoint
  }
}

resource "aws_launch_template" "ec2_windows_runner_launch_template" {
  name = "ec2_windows_runner_launch_template"

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
    }
  }

  image_id                             = var.windows_runner_ami
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.windows_runner_instance_type
  key_name                             = var.windows_server_keypair
  metadata_options {
    #  http_endpoint               = "enabled"
    #  http_tokens                 = "required"
    #  http_put_response_hop_limit = 1
    #  instance_metadata_tags      = "enabled"
    #}
    network_interfaces {
      associate_public_ip_address = true
    }
    placement {
      availability_zone = "us-east-1a"
    }
    vpc_security_group_ids = [var.windows_runner_security_groups]
    tag_specifications {
      resource_type = "instance"
      tags          = var.default_tags
    }
    user_data = filebase64("${path.module}/example.sh")
  }
}


resource "aws_autoscaling_group" "ec2_windows_runner_asg" {
  name                 = "ec2_windows_runner_asg"
  availability_zones   = ["us-east-1a"]
  desired_capacity     = 0
  max_size             = 1
  min_size             = 0
  termination_policies = ["OldestInstance"]
  launch_template {
    id      = aws_launch_template.ec2_windows_runner_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "machine_runner_type"
    value               = "windows"
    propagate_at_launch = "true"
  }

  dynamic "tag" {
    for_each = var.default_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
