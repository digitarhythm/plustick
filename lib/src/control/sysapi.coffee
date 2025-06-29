Promise = require("bluebird")
express = require("express")
router = express.Router()
path = require("path")
config = require("config")
echo = require("ndlog").echo
bind_router = global.BIND_ROUTER
fs = require("fs-extra")
pathinfo = require("#{PLUSTICKLIBS}/pathinfo.min.js")

router.use(express.json())
router.use(express.urlencoded({ extended: true }))

NODE_ENV = process.env['NODE_ENV']

__systemdir = fs.realpathSync(__dirname+"/../../..")
__sysjsdir = "#{__systemdir}/lib/js"
__sysjsctrl = "#{__sysjsdir}/control"

PATHINFO = require("#{__sysjsctrl}/pathinfo.min.js")
if (NODE_ENV == "develop")
  ENVJSON = require("#{PATHINFO.appsdir}/config/develop.json")
else
  ENVJSON = require("#{PATHINFO.appsdir}/config/default.json")

envpath = ENVJSON.application.path
if (envpath == "")
  SUBPATH = ""
else
  SUBPATH = "/#{envpath}"

#=============================================================================
# normal api
#=============================================================================
router.all "/:endpoint", (req, res) ->
  method = req.method
  endpoint = req.params.endpoint
  data = req.body
  query = req.query
  headers = req.headers
  headers['method'] = method

  if (NODE_ENV != "develop")
    origin = "#{headers.origin}#{SUBPATH}"
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
    lists = await readFileList(pathinfo.usrjsview).catch (e) =>
      console.log(e)

    jsfilelist['userjsview'] = []
    for fname in lists
      if (fname.match(/^.*\.min\.js$/))
        if (fname.match(/appsmain\.min\.js$/) == null)
          jsfilelist['userjsview'].push("#{pathinfo.pkgname}/view/#{fname}")

    res.json
      jrror: 0
      pathinfo: pathinfo
      jsfilelist: jsfilelist

  else
    if (bind_router[endpoint]? && typeof(bind_router[endpoint]) == 'function')
      ret = await (bind_router[endpoint])(headers, data, query)
      res.json(ret)

module.exports = router

