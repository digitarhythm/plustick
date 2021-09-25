Promise = require("bluebird")
path = require("path")
config = require("config")
fs = require("fs-extra")
echo = require("ndlog").echo
packjson = require("#{HOMEDIR}/package.json")

#=============================================================================
# API Sample
#=============================================================================
BIND_ROUTER.version = (headers, data) ->
  return new Promise (resolve, reject) =>
    version = packjson.version
    ret =
      version: version

    resolve(ret)

