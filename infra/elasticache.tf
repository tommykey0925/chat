resource "aws_elasticache_subnet_group" "chat" {
  name       = "${var.project}-redis"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Project = var.project
  }
}

resource "aws_elasticache_cluster" "chat" {
  cluster_id         = "${var.project}-redis"
  engine             = "redis"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  security_group_ids = [aws_security_group.redis.id]
  subnet_group_name  = aws_elasticache_subnet_group.chat.name

  tags = {
    Project = var.project
  }
}
