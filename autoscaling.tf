// 对哪个ECS服务进行自动扩容
resource "aws_appautoscaling_target" "taskoverflow" {
    max_capacity = 4
    min_capacity = 1
    resource_id = "service/taskoverflow/taskoverflow"
    scalable_dimension = "ecs:service:DesiredCount" // 这个是扩容的维度，ECS服务的期望数量(具体来说,就是这个服务要运行几个副本)
    service_namespace = "ecs"
    depends_on = [ aws_ecs_service.taskoverflow ]
}
// 定义具体的扩容规则,以下是对CPU进行自动扩容,当平均 CPU 超过 20% 就会扩容，低于就缩容
resource "aws_appautoscaling_policy" "taskoverflow-cpu" {
    name = "taskoverflow-cpu"
    policy_type = "TargetTrackingScaling"
    resource_id = aws_appautoscaling_target.taskoverflow.resource_id
    scalable_dimension = aws_appautoscaling_target.taskoverflow.scalable_dimension
    service_namespace = aws_appautoscaling_target.taskoverflow.service_namespace
    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
    target_value = 20
    }
}