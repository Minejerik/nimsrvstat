# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import nimsrvstat

test "Getting Data":
  var server: Server

  server = Server(
    address: "hypixel.net",
    platform: Java
  )

  server.getData

  echo server.getDebug

  check true == true

test "Ip test":
  var server: Server

  server = Server(
    address: "hypixel.net",
    platform: Java
  )

  server.getData

  check server.getNetwork().ip[0..10] == "209.222.115" 