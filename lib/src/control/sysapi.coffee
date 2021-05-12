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

router.all "/:endpoint", (req, res) ->
  method = req.method
  endpoint = req.params.endpoint
  data = req.body
  headers = req.headers
  headers['method'] = method

  origin = headers.origin
  referer = headers.referer || ""
  if (origin != referer.replace(/\/$/, ""))
    res.json(-1)

  if (endpoint == "__getappsinfo__")
    readFileList = (path) ->
      return new Promise (resolve, reject) ->
        fs.readdir path, (err, lists) ->
          if (err)
            reject(err)
          else
            resolve(lists)

    # splash image file
    fpath = "#{pathinfo.usrlibdir}/splash.png"
    try
      err = fs.openSync(fpath, 'r')
    catch e
      fpath = "#{pathinfo.pkgname}/usrlib/OGP.png"

    # make load Javascript file list
    jsfilelist =
      plugin: []
      view: []
      include: []
    lists = await readFileList(pathinfo.plugindir)
    for fname in lists
      if (fname.match(/^.*\.js$/))
        jsfilelist['plugin'].push("#{pathinfo.pkgname}/plugin/#{fname}")
    lists = await readFileList(pathinfo.usrjsview)
    for fname in lists
      if (fname.match(/^.*\.min\.js$/))
        jsfilelist['view'].push("#{pathinfo.pkgname}/view/#{fname}")
    lists = await readFileList(pathinfo.syslibdir)
    for fname in lists
      if (fname.match(/^.*\.min\.js$/))
        jsfilelist['include'].push("#{pathinfo.pkgname}/include/#{fname}")
    res.json
      error: 0
      splash: fpath
      jsfilelist: jsfilelist

  else
    if (bind_router[endpoint]? && typeof(bind_router[endpoint]) == 'function')
      bind_router[endpoint](headers, data).then (ret)=>
        res.json(ret)
      .catch (e)=>
        res.json
          error: e

module.exports = router

