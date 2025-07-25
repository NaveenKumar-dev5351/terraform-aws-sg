#roboshop-dev-frontend
resource "aws_security_group" "roboshoptf" {
  name        = sg_name
  description = sg_description
  vpc_id      = var.vpc_id

  tags = merge (
    var.sg_tags,
    local.common_tags,
    {
        name = "${var.project}-${var.environment}-${var.sg_name}"
    }
  )

}