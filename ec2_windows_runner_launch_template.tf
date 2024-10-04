resource "aws_launch_template" "ec2_windows_runner_launch_template" {
  name = "ec2_windows_runner_launch_template"

  block_device_mappings {
    #device_name = "/dev/sdf"
    ebs {
      volume_size = 20
    }
  }

  image_id = var.ec2_bastion_ami
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  key_name = var.support_server_keypair
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
    availability_zone = "us-east-2a"
  }
  vpc_security_group_ids = [var.mp_sg_id]
  tag_specifications {
    resource_type = "instance"
    tags          = var.default_tags
  }
  user_data = filebase64("${path.module}/example.sh")
}

resource "aws_autoscaling_group" "ec2_windows_runner_asg" {
  name = "ec2_windows_runner_asg"
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
#}
