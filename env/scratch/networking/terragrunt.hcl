terraform {
  source = "../../../aws//networking"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  service_name = "rp-simulator"
}
