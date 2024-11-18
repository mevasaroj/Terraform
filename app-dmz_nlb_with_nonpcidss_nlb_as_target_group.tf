##################################################################################################################################################
########### REMOTE VPC, SUBNET and SECURITY GROUP VALUES DECLARATION     ##############################################
##################################################################################################################################################


##################################################################################################################################################
########### 01.START OF HBL-AWS-APS1-VKYC-INBOUND-PROD-NLB     ##############################################
##################################################################################################################################################
module "hbl-aws-vkyc-dmz-prod-nlb" {
  source              = "terraform.hdfcbank.com/HDFCBANK/module/aws//modules/aws-load-balancer"
  name                = join("-", [local.org, local.csp, local.account, "dmz-nlb"])  # - Max 32 Characters
  load_balancer_type  = "network"
  internal            = true
  preserve_host_header       = false
  drop_invalid_header_fields = false
  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true
  desync_mitigation_mode     = "defensive"
  vpc_id             = var.dmz-prod-vpc

  access_logs         = {
    bucket ="hbl-aws-aps1-vkyc-nonpcidss-prod-load-balancer-bucket"
    prefix = join("-", [local.org, local.csp, local.account, "dmz-nlb"])
    enabled = true
  }

  subnet_mapping = [
    {
      subnet_id = var.dmz-prod-web-subnet-aza
      private_ipv4_address = "10.199.89.5"
    },
    {
      subnet_id = var.dmz-prod-web-subnet-azb
      private_ipv4_address = "10.199.89.70"
    },
    {
      subnet_id = var.dmz-prod-web-subnet-azc
      private_ipv4_address = "10.199.89.134"
   }
  ]
#================================================================================================================================================================
## START OF Listeners
  http_tcp_listeners = [
    # LISTENER - target_group_index = 0
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
     },
  ]  
 ## END OF Listener
#================================================================================================================================================================
  ## Start OF Target Group
  target_groups = [
    ## TARGET GROUP - target_group_index = 0
    {
      name               = join("-", [local.org, local.csp, local.account, "dmz-nlb-tg"])
      backend_protocol   = "TCP"
      backend_port       = 443
      target_type        = "ip"
      preserve_client_ip = true
      targets = {
        target1 = {
          target_id = "10.199.99.5"
          port = 443
	      availability_zone = "ap-south-1a"
        },
      target2 = {
          target_id = "10.199.99.133"
          port = 443
	      availability_zone = "ap-south-1b"
        },
        target3 = {
          target_id = "10.199.100.5"
          port = 443
	      availability_zone = "ap-south-1c"
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
      tags = merge({ application = "dmz-nlb-tg",
          tier = "target-group"},
        var.additional_tags )
      }
  ]  
## END OF Target Group
#================================================================================================================================================================
  tags = merge(
    { Name = join("-", [local.org, local.csp, local.account, "dmz-nlb"]), }, 
    var.additional_tags
  )
} 
## END OF NLB
#================================================================================================================================================================
##################################################################################################################################################
########### 01.END OF  HBL-AWS-APS1-VKYC-INBOUND-PROD-NLB    ##############################################
##################################################################################################################################################