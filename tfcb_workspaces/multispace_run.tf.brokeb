#resource "multispace_run" "hcp_consul" {
  # Use string workspace names here and not data sources so that
  # you can define the multispace runs before the workspace even exists.
#  organization = var.organization
#  workspace    = "hcp_consul"
#}

resource "multispace_run" "aws_network" {
  workspace    = "aws-tgw"
  organization = var.organization
  #depends_on   = [multispace_run.hcp_consul]
}