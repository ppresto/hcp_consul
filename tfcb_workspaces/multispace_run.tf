resource "multispace_run" "hcp_consul" {
  # Use string workspace names here and not data sources so that
  # you can define the multispace runs before the workspace even exists.
  organization = "presto-projects"
  workspace    = "hcp_consul"
}

resource "multispace_run" "aws_network" {
  workspace    = "aws_network"
  organization = var.organization
  depends_on   = [multispace_run.hcp_consul]
}

resource "multispace_run" "root" {
  organization = "my-org"
  workspace    = "tfc"
  manual_confirm = true
}