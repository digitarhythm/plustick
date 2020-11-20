Promise = require("bluebird")
path = require("path")
config = require("config")
fs = require("fs-extra")
echo = require("ndlog").echo
BIND_ROUTER = global.BIND_ROUTER

#=============================================================================
# API Sample
#=============================================================================
BIND_ROUTER.version = (headers, data)->
  return new Promise (resolve, reject)=>
    packjson = require("#{global.ROOTDIR}/package.json")
    ret =
      version: packjson.version

    resolve(ret)

