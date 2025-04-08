// 创建Target Group
resource "aws_lb_target_group" "taskoverflow" {
    name     = "taskoverflow"          # 目标组的名称
    port     = 6400                    # 接收请求的端口
    protocol = "HTTP"                 # 使用 HTTP 协议处理请求
    vpc_id   = aws_security_group.taskoverflow.vpc_id  # 所在的 VPC
    target_type = "ip"                # 使用 IP 地址作为目标（而不是 EC2 实例）
    
    // 健康检查部分
    health_check {
        path = "/api/v1/health"
        port = "6400"
        protocol = "HTTP"
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 5
        interval = 10
    }
}
// 创建负载均衡器
resource "aws_lb" "taskoverflow" {
    name = "taskoverflow"                         // 名称叫 taskoverflow
    internal = false                              // 这是一个外部可访问的负载均衡器（不是内部的）
    load_balancer_type = "application"            // 类型是“应用型”负载均衡器（Layer 7）
    subnets = data.aws_subnets.private.ids        // 部署在哪些子网（子网 ID 从 data 源获取）
    security_groups = [aws_security_group.taskoverflow_lb.id]  // 关联的安全组（见下面那段代码）
}

// 创建安全组
resource "aws_security_group" "taskoverflow_lb" {
    name = "taskoverflow_lb"                      // 安全组名称
    description = "TaskOverflow Load Balancer Security Group"  // 功能描述

    ingress {
        from_port = 80                            // 允许进入的端口（HTTP）
        to_port = 80
        protocol = "tcp"                          // 协议是 TCP
        cidr_blocks = ["0.0.0.0/0"]               // 允许所有 IP 访问（0.0.0.0/0）
    }

    egress {
        from_port = 0                             // 出站规则，允许所有端口
        to_port = 0
        protocol = "-1"                           // 所有协议
        cidr_blocks = ["0.0.0.0/0"]               // 允许所有 IP 出站
    }

    tags = {
        Name = "taskoverflow_lb_security_group"   // 给资源打一个标签
    }
}
// 为负载均衡器添加一个监听器（Listener），监听来自用户的 HTTP 请求（80 端口），
// 并把这些请求转发到目标组（Target Group）中运行的服务实例上
resource "aws_lb_listener" "taskoverflow" {
    load_balancer_arn = aws_lb.taskoverflow.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.taskoverflow.arn
    }
}
// 输出你创建的 Load Balancer（负载均衡器）的 DNS 名称
output "taskoverflow_dns_name" {
    value = aws_lb.taskoverflow.dns_name
    description = "DNS name of the TaskOverflow load balancer."
}