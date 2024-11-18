module "gng_nlb" {
  source  = "terraform.hdfcbank.com/HDFCBANK/module/aws//modules/aws-load-balancer"
  version = "1.1.1"
  name                = join("-", [local.org, local.csp, local.account, "nonpcidss-nlb"])  # - Max 32 Characters
  load_balancer_type  = "network"
  internal            = true
  preserve_host_header       = false
  drop_invalid_header_fields = false
  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true
  desync_mitigation_mode     = "defensive"
  vpc_id             = var.nonpcidss-prod-vpc

  access_logs         = {
    bucket = "hbl-aws-aps1-vkyc-nonpcidss-prod-load-balancer-bucket"
    prefix = join("-", [local.org, local.csp, local.account, "nonpcidss-nlb"])
    enabled = true
  }
  
  subnet_mapping = [
    {
      subnet_id = var.nonpcidss-prod-app-subnet-aza
      private_ipv4_address = "10.196.136.6"
    },
    {
      subnet_id = var.nonpcidss-prod-app-subnet-azb
      private_ipv4_address = "10.196.136.135"
    },
    {
      subnet_id = var.nonpcidss-prod-app-subnet-azc
      private_ipv4_address = "10.196.137.6"
   }
  ]
#================================================================================================================================================================
## START OF Listeners
  http_tcp_listeners = [
    # GNG ALB LISTENER - target_group_index = 0
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
      load_balancer_arn  = "arn:aws:elasticloadbalancing:ap-south-1:385089911239:loadbalancer/app/hbl-aws-aps1-nonpcidss-gng-alb/9d0c813023fc1118" 
     },
  ]  
 ## END OF Listener
#================================================================================================================================================================
  ## Start OF Target Group
  target_groups = [
    ## GNG ALB AS A TARGET GROUP - target_group_index = 0
    {
      name               = join("-", [local.org, local.csp, local.account, "nonpcidss-nlb-tg"])
      backend_protocol   = "TCP"
      backend_port       = 443
      target_type        = "alb"
      preserve_client_ip = true
      targets = {
        target1 = {
          target_id = "arn:aws:elasticloadbalancing:ap-south-1:385089911239:loadbalancer/app/hbl-aws-aps1-nonpcidss-gng-alb/9d0c813023fc1118"
          port = 443
        },
      }
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTPS"
        healthy_threshold   = 3
        unhealthy_threshold = 3
	timeout             = 6
      }
      tags = merge({ application = "nonpcidss-nlb-tg",
          tier = "target-group"},
        var.additional_tags )
      }
  ]  
## END OF Target Group
#================================================================================================================================================================
  tags = merge(
    { Name = join("-", [local.org, local.csp, local.account, "nonpcidss-nlb"]), }, 
    var.additional_tags
  )
} 
## END OF NLB
#================================================================================================================================================================