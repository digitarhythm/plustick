express = require("express")
router = express.Router()
app = express()
Promise = require("bluebird")
execSync = require("child_process").execSync
exphttp = require("http").Server(app)
httpolyglot = require("httpolyglot")
path = require("path")
config = require("config")
fs = require("fs-extra")
echo = require("ndlog").echo
process = require("process")
sharp = require("sharp")
axios = require("axios")
ECT = require("ect")

__systemdir = fs.realpathSync(__dirname+"/../../..")
__sysjsdir = "#{__systemdir}/lib/js"
__sysjsctrl = "#{__sysjsdir}/control"
PATHINFO = require("#{__sysjsctrl}/pathinfo.min.js")

APPSJSON = require("#{PATHINFO.homedir}/config/application.json")
SYSJSON = require("#{PATHINFO.systemdir}/lib/config/system.json")
PKGJSON = require("#{process.cwd()}/package.json")

NODE_ENV = process.env.NODE_ENV || "production"
START_URL = APPSJSON.site.start_url[NODE_ENV]
LISTEN_PORT = undefined

MANIFEST_TMP = undefined
MANIFEST_URI = undefined
MANIFEST_PATH = undefined
SERVICEWORKER_TMP = undefined
SERVICEWORKER_PATH = undefined

CSSFILELIST = undefined
JSSYSLIST = undefined
JSFILELIST = undefined
SITEJSON = undefined
SYSTEMCSS = undefined
SNSJSON = undefined

global.BIND_ROUTER = {}
global.APPSDIR = PATHINFO.homedir
global.PLUSTICKLIBS = PATHINFO.sysjsctrl

SYSAPI = require("#{PATHINFO.sysjsctrl}/sysapi.min.js")
app.use("/#{PATHINFO.pkgname}/api", SYSAPI)

NETCONF = config.network

echo "application loading time: [#{new Date().toLocaleString("ja-JP")}]"

#----------------------------------
# template engine
#----------------------------------
app.set("views", PATHINFO.templatedir)
ectRenderer = ECT({ watch: true, root: PATHINFO.templatedir, ext : ".ect" })
app.engine("ect", ectRenderer.render)
app.set("view engine", "ect")

#==========================================================================
#==========================================================================
#==========================================================================
#
# Function
#
#==========================================================================
#==========================================================================
#==========================================================================

#==========================================================================
# uri directory binding
#==========================================================================
directoryBinding = ->
  app.use("/", express.static(PATHINFO.publicdir))
  app.use("/#{PATHINFO.pkgname}/plugin", express.static(PATHINFO.plugindir))
  app.use("/#{PATHINFO.pkgname}/stylesheet", express.static(PATHINFO.stylesheetdir))
  app.use("/#{PATHINFO.pkgname}/public", express.static(PATHINFO.publicdir))
  app.use("/#{PATHINFO.pkgname}/view", express.static(PATHINFO.usrjsview))
  app.use("/#{PATHINFO.pkgname}/syslib", express.static(PATHINFO.sysjsview))
  app.use("/#{PATHINFO.pkgname}/include", express.static(PATHINFO.syslibdir))
  app.use("/#{PATHINFO.pkgname}/template", express.static(PATHINFO.templatedir))

#==========================================================================
# read file list function
#==========================================================================
__readFileList = (path) ->
  try
    lists = fs.readdirSync(path)
    return(lists)
  catch e
    return(e)

#==========================================================================
# Library file include
#==========================================================================
libfileInclude = ->
  #----------------------------------
  # user API import
  #----------------------------------
  lists = __readFileList(PATHINFO.usrctrldir)
  for fname in lists
    if (fname.match(/^.*\.js$/))
      require "/#{PATHINFO.usrctrldir}/#{fname}"

  #----------------------------------
  # make directory file list
  #----------------------------------
  CSSFILELIST = [].concat(SYSJSON.additional.front.css) || []
  CSSFILELIST = CSSFILELIST.concat(APPSJSON.additional.front.css)
  JSSYSLIST = [].concat(SYSJSON.additional.front.javascript) || []
  JSSYSLIST = JSSYSLIST.concat(APPSJSON.additional.front.javascript)

  #----------------------------------
  # User CSS file include
  #----------------------------------
  lists = __readFileList(PATHINFO.stylesheetdir)
  for fname in lists
    if (fname.match(/^.*\.css$/))
      CSSFILELIST.push("#{PATHINFO.pkgname}/stylesheet/#{fname}")

  #----------------------------------
  # User plugin include
  #----------------------------------
  lists = __readFileList(PATHINFO.plugindir)
  for fname in lists
    if (fname.match(/^.*\.js$/))
      JSSYSLIST.push("#{PATHINFO.pkgname}/plugin/#{fname}")

  #----------------------------------
  # System library include
  #----------------------------------
  lists = __readFileList(PATHINFO.syslibdir)
  for fname in lists
    if (fname.match(/^.*\.min\.js$/))
      JSSYSLIST.push("#{PATHINFO.pkgname}/include/#{fname}")

#==========================================================================
# get free port
#==========================================================================
get_free_port = (start, num=1, exclude_port=[]) ->
  port = execSync("sudo -i netstat -an | grep 'LISTEN ' | awk 'match($4, /[\:\.][0-9]*$/) {print substr($4, RSTART+1, RLENGTH)}' | sort -nu").toString().trim()
  portlist = port.split("\n")
  exclude_port.forEach (p) ->
    portlist.push(p)
  freeport = []
  portlist.forEach (p, idx) ->
    portlist[idx] = parseInt(p)
  for i in [parseInt(start)...(parseInt(start)+1000)]
    if (portlist.indexOf(i) < 0)
      freeport.push(i)
      if (freeport.length == num)
        break
      else
        portlist.push(i)
  return freeport

#==============================================================================
# generate manifest.json
#==============================================================================
generateManifest = ->
  manifest = fs.readFileSync(MANIFEST_TMP, 'utf8')
  manifest = manifest.replace(/\[\[\[:short_name:\]\]\]/, PKGJSON.name)
  manifest = manifest.replace(/\[\[\[:name:\]\]\]/, PKGJSON.name)
  manifest = manifest.replace(/\[\[\[:start_url:\]\]\]/, START_URL)
  manifest = manifest.replace(/\[\[\[:display:\]\]\]/, APPSJSON.site.pwa.display)
  manifest = manifest.replace(/\[\[\[:theme_color:\]\]\]/, APPSJSON.site.pwa.theme_color)
  manifest = manifest.replace(/\[\[\[:background_color:\]\]\]/, APPSJSON.site.pwa.background_color)
  manifest = manifest.replace(/\[\[\[:orientation:\]\]\]/, APPSJSON.site.pwa.orientation)
  fs.writeFileSync(MANIFEST_PATH, manifest, 'utf8')

#==============================================================================
# generate service worker
#==============================================================================
generateServiceworker = ->
  uri = "#{START_URL}/#{PATHINFO.pkgname}/api/__getappsinfo__"
  ret = await axios.get(uri)
  JSFILELIST = ret.data.jsfilelist['userjsview']

  serviceworker = fs.readFileSync(SERVICEWORKER_TMP, 'utf8')
  serviceworker = serviceworker.replace(/\[\[\[:name:\]\]\]/, PKGJSON.name)
  serviceworker = serviceworker.replace(/\[\[\[:version:\]\]\]/, PKGJSON.version)

  cache_contents_list = ["\"/\"", "  \"/#{PATHINFO.pkgname}/template/system.css\""]

  CSSFILELIST.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  JSSYSLIST.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  JSFILELIST.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  cache_contents = cache_contents_list.join(",\n")
  serviceworker = serviceworker.replace(/\[\[\[:cache_contents:\]\]\]/, cache_contents)
  fs.writeFileSync(SERVICEWORKER_PATH, serviceworker, 'utf8')

#==============================================================================
# generate ICON file
#==============================================================================
generateIconFile = ->
  imgpath = "#{PATHINFO.publicdir}/img/OGP.png"
  pathtmp = "#{PATHINFO.publicdir}/img/icons/icon-###x###.png"
  sizelist = [72, 96, 128, 144, 152, 192, 384, 512]

  convimage = (size) ->
    topath = pathtmp.replace(/###/g, size)
    await sharp(imgpath)
      .resize
        width: size,
        height: size,
        fit: "cover"
      .toFile(topath)

  for size in sizelist
    convimage(size)

#==============================================================================
# startserver listen
#==============================================================================
startserver = ->
  switch (NETCONF.protocol)
    when "http"
      await exphttp.listen(LISTEN_PORT)
      console.log("listening HTTP:", LISTEN_PORT)

    when "https"
      app.use (req, res, next) ->
        if (!req.secure)
          res.redirect(301, 'https://' + req.hostname + ':LISTEN_PORT' + req.originalUrl)
        next()
      options =
        key: fs.readFileSync(NETCONF.ssl_key)
        cert: fs.readFileSync(NETCONF.ssl_cert)
      httpolyglot.createServer(options, app).listen(LISTEN_PORT)
      console.log("listening HTTP/HTTPS:", LISTEN_PORT)

  module.exports = router

#==============================================================================
# Application Initialize
#==============================================================================
appsInit = ->
  SYSTEMCSS = "#{PATHINFO.pkgname}/template/system.css"
  SITEJSON = APPSJSON.site || {}
  SNSJSON = APPSJSON.sns || {}
  MANIFEST_TMP = "#{PATHINFO.templatedir}/manifest.json"
  MANIFEST_URI = "/#{PATHINFO.pkgname}/public/manifest.json"
  MANIFEST_PATH = "#{PATHINFO.publicdir}/manifest.json"
  SERVICEWORKER_TMP = "#{PATHINFO.templatedir}/serviceworker.js"
  SERVICEWORKER_PATH = "#{PATHINFO.publicdir}/serviceworker.js"

  if (NETCONF? && NETCONF.port?)
    port = NETCONF.port

  if (port == "any")
    start_port = parseInt(NETCONF.start_port) || 3000
    port = parseInt(get_free_port(start_port))

  LISTEN_PORT = port

#==========================================================================
# router setting
#==========================================================================
app.get "/", (req, res) ->
  #----------------------------------
  # Template engine value
  #----------------------------------
  title = PKGJSON.name
  site_name = PKGJSON.name
  description = PKGJSON.description

  #----------------------------------
  # Production build
  #----------------------------------
  if (NODE_ENV == "production")
    # Site info
    if (SITEJSON?)
      favimg = SITEJSON.favicon || ""
    else
      favimg = ""

    # SNS info
    if (SNSJSON?)
      ogpimg = SNSJSON.ogp || "OGP.png"
      twitter = SNSJSON.twitter || ""
      facebook = SNSJSON.facebook || ""
    else
      ogpimg = ""
      twitter = ""
      facebook = ""
  else
    favimg = SITEJSON.favicon || ""
    ogpimg = SNSJSON.ogp || "OGP.png"
    twitter = SNSJSON.twitter || ""
    facebook = SNSJSON.facebook || ""

  #----------------------------------
  # Site info
  #----------------------------------
  if (SITEJSON?)
    site_origin = SITEJSON.origin || ""
  else
    site_origin = ""

  #----------------------------------
  # rendering HTML
  #----------------------------------
  res.render "main",
    pkgname: PATHINFO.pkgname
    systemcss: SYSTEMCSS
    cssfilelist: CSSFILELIST
    jssyslist: JSSYSLIST
    node_env: NODE_ENV
    origin: site_origin
    ogpimg: ogpimg
    favimg: favimg
    title: title
    site_name: site_name
    description: description
    twitter: twitter
    facebook: facebook
    manifest: MANIFEST_URI

#==========================================================================
# execute modules
#==========================================================================
appsInit()
directoryBinding()
libfileInclude()
generateManifest()
generateServiceworker()
generateIconFile()
startserver()

