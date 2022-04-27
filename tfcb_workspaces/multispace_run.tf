resource "multispace_run" "hcp_consul" {
  # Use string workspace names here and not data sources so that
  # you can define the multispace runs before the workspace even exists.
  workspace    = "hcp_consul"
  organization = var.organization
  retry        = true
}

resource "multispace_run" "aws_network" {
  workspace    = "aws_network"
  organization = var.organization
  depends_on   = [multispace_run.hcp_consul]
}