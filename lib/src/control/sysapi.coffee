express = require("express")
router = express.Router()
Promise = require("bluebird")
path = require("path")
config = require("config")
echo = require("ndlog").echo
bind_router = global.BIND_ROUTER
fs = require("fs-extra")
pathinfo = require("#{PLUSTICKLIBS}/pathinfo.min.js")

router.use(express.json())
router.use(express.urlencoded({ extended: true }))

node_env = process.env['NODE_ENV']

#=============================================================================
# normal api
#=============================================================================
router.all "/:endpoint", (req, res) ->
  method = req.method
  endpoint = req.params.endpoint
  data = req.body
  headers = req.headers
  headers['method'] = method

  if (node_env == "production")
    origin = headers.origin
    referer = headers.referer.replace(/\/\?.*$/, "") || ""
    if (origin != referer.replace(/\/$/, ""))
      res.json(-1)
      return

  #--------------------------
  # get application info from server
  #--------------------------
  if (endpoint == "__getappsinfo__")
    readFileList = (path) ->
      return new Promise (resolve, reject) ->
        fs.readdir path, (err, lists) ->
          if (err)
            reject(err)
          else
            resolve(lists)

    # make load Javascript file list
    jsfilelist = {}
    lists = await readFileList(pathinfo.usrjsview)

    jsfilelist['userjsview'] = []
    for fname in lists
      if (fname.match(/^.*\.min\.js$/))
        if (fname.match(/appsmain\.min\.js$/) == null)
          jsfilelist['userjsview'].push("#{pathinfo.pkgname}/view/#{fname}")

    res.json
      error: 0
      pathinfo: pathinfo
      jsfilelist: jsfilelist

  else
    if (bind_router[endpoint]? && typeof(bind_router[endpoint]) == 'function')
      bind_router[endpoint](headers, data).then (ret)=>
        res.json(ret)
      .catch (e)=>
        res.json
          error: e

module.exports = router

