terraform {
  source = "../../../aws//ecr"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  image_name = "rp-simulator"
}
