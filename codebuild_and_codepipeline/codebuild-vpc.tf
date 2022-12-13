resource "aws_subnet" "codebuild_subnet" {
  availability_zone = var.codebuild_az
  vpc_id            = var.avtx_ctrl_vpc
  cidr_block        = var.codebuild_cidr_block

  tags = {
    Name = "codebuild_subnet"
  }
}

resource "aws_route_table" "rt_for_codebuild" {

  vpc_id = var.avtx_ctrl_vpc


  tags = {
    Name = "Route table for codebuild"
  }
}

resource "aws_route_table_association" "privassoc" {

  subnet_id      = aws_subnet.codebuild_subnet.id
  route_table_id = aws_route_table.rt_for_codebuild.id

}

resource "aws_eip" "natgw_eip" {
  vpc = true
}

resource "aws_security_group" "CodebuildSecurityGroup" {
  name        = "CodebuildSecurityGroup"
  description = "CodebuildSecurityGroup"
  vpc_id      = var.avtx_ctrl_vpc

}

resource "aws_security_group_rule" "ingress_rule_for_codebuild" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.CodebuildSecurityGroup.id
}

resource "aws_security_group_rule" "egress_rule_for_codebuild" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.CodebuildSecurityGroup.id
}

resource "aws_security_group_rule" "ingress_rule_for_avx_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.CodebuildSecurityGroup.id
  security_group_id        = var.AviatrixSecurityGroupID
}