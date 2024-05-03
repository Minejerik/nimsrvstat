# Package

version       = "0.1.0"
author        = "minejerik"
description   = "A pacakge to interact with mcsrvstat from nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.14"


# External dependencies.
when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"