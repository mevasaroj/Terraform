module "gotrust-app-alb" {
  source              = "terraform.hdfcbank.com/HDFCBANK/module/aws//modules/aws-load-balancer"
  version             = "1.1.1"
  name                = join("-", [local.org, local.csp, local.region, local.vpcname, "gotst-alb"])  # - Max 32 Characters
  vpc_id              = var.nonpcidss-prod-vpc
  load_balancer_type  = "application"
  subnets             = [var.nonpcidss-prod-app-subnet-aza, var.nonpcidss-prod-app-subnet-azb, var.nonpcidss-prod-app-subnet-azc]
  security_groups     = ["${var.nonpcidss-prod-lb-sg}"]
  internal            = true
  drop_invalid_header_fields = true
  enable_deletion_protection = true
  access_logs         = {
    bucket = "hbl-aws-aps1-vkyc-nonpcidss-prod-load-balancer-bucket"
    prefix = join("-", [local.org, local.csp, local.region, local.vpcname, "gotst-alb"])
    enabled = true
  }	
  #==========================================================================
  ## START OF Listeners
  https_listeners = [
     # UAM APP Listener 
     {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 2
      action_type        = "fixed-response"
      fixed_response = {
        content_type = "text/html"
        message_body = "You are not authorized to access this resource."
        status_code  = "200"
      },
      certificate_arn    = var.gotrust_certificate_arn
      ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    },
  ]
  ## END OF Listener
  #==========================================================================
  ## START OF TARGET GROUP --  target_group_index = 0 
  target_groups = [
    ## PTL APPLICATION TARGET GROUP - gotrust - web
      {
      name             = join("-", [local.org, local.csp, local.region, local.vpcname, "ptl-tg"])
      backend_protocol = "HTTPS"
      backend_port     = 443
      target_type      = "instance"
      protocol_version = "HTTP1"
      deregistration_delay = 10
      targets = {
        target1 = {
          target_id = var.gng-ptl-app-instances[0]
          port = 443
        },
        target2 = {
          target_id = var.gng-ptl-app-instances[1]
          port = 443
        },
      }
      health_check = {
       path                = "/"
       enabled             = true
       interval            = 30        
       port                = 443
       healthy_threshold   = 3
       unhealthy_threshold = 5
       timeout             = 5
       protocol            = "HTTPS"
       matcher             = "200-399"
      }
    	tags = merge( { application = "ptl-web-app" }, 
        var.additional_tags
      )
     }   
  ]
  ## END OF TARGET GROUP
  #==========================================================================
  # START OF Listener Rule
  https_listener_rules = [     
    ## PTL Listener Rule
     {
      https_listener_index = 0
      priority             = 1
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        host_headers = ["gotrust.hdfcbankapps.com"]
       },
       {
        path_patterns = ["/web/*"]
       }]
    },
  ]
  ## END OF Listener Rule	
  #==========================================================================
}
	
#============================================================
### END OF ALB ####
#============================================================