Promise = require("bluebird")
express = require("express")
router = express.Router()
app = express()
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

#----------------------------------
# super global value
#----------------------------------
global.BIND_ROUTER = {}
global.PLUSTICKLIBS = PATHINFO.sysjsctrl

global.HOMEDIR = PATHINFO.homedir
global.APPSDIR = PATHINFO.appsdir
global.PUBLICDIR = PATHINFO.publicdir
global.LIBDIR = PATHINFO.libdir
global.PLUGINDIR = PATHINFO.plugindir
global.STYLESHEETDIR = PATHINFO.stylesheetdir

#----------------------------------
# global value
#----------------------------------
APPSJSON = require("#{PATHINFO.appsdir}/config/application.json")
SYSJSON = require("#{PATHINFO.systemdir}/lib/config/system.json")
SYSAPI = require("#{PATHINFO.sysjsctrl}/sysapi.min.js")
PKGJSON = require("#{process.cwd()}/package.json")

NODE_ENV = process.env.NODE_ENV || "production"
if (NODE_ENV == "develop")
  ENVJSON = require("#{PATHINFO.appsdir}/config/develop.json")
else
  ENVJSON = require("#{PATHINFO.appsdir}/config/default.json")

LISTEN_PORT = undefined

envpath = ENVJSON.application.path
if (envpath == "")
  SUBPATH = ""
else
  SUBPATH = "/#{envpath}"

SITE_NAME = PKGJSON.name

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

PKGNAME = PATHINFO.pkgname
PWA = if (APPSJSON.site.pwa.installed == true) then "activate" else "inactivate"

NETCONF = config.network

if (APPSJSON.site.display?)
  SITE_WIDTH = APPSJSON.site.display.width || "any"
  SITE_HEIGHT = APPSJSON.site.display.height || "any"
else
  SITE_WIDTH = "any"
  SITE_HEIGHT = "any"

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
  app.use("/", express.static(PATHINFO.libdir))
  app.use("#{SUBPATH}/#{PKGNAME}/plugin", express.static(PATHINFO.plugindir))
  app.use("#{SUBPATH}/#{PKGNAME}/stylesheet", express.static(PATHINFO.stylesheetdir))
  app.use("#{SUBPATH}/#{PKGNAME}/public", express.static(PATHINFO.publicdir))
  app.use("#{SUBPATH}/#{PKGNAME}/view", express.static(PATHINFO.usrjsview))
  app.use("#{SUBPATH}/#{PKGNAME}/lib", express.static(PATHINFO.libdir))
  app.use("#{SUBPATH}/#{PKGNAME}/syslib", express.static(PATHINFO.sysjsview))
  app.use("#{SUBPATH}/#{PKGNAME}/include", express.static(PATHINFO.syslibdir))
  app.use("#{SUBPATH}/#{PKGNAME}/template", express.static(PATHINFO.templatedir))
  app.use("#{SUBPATH}/#{PKGNAME}/api", SYSAPI)

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
  JSSYSLIST = []

  #----------------------------------
  # User CSS file include
  #----------------------------------
  lists = __readFileList(PATHINFO.stylesheetdir)
  for fname in lists
    if (fname.match(/^.*\.css$/))
      CSSFILELIST.push("#{SITE_NAME}/stylesheet/#{fname}")

  #----------------------------------
  # User plugin include
  #----------------------------------
  lists = __readFileList(PATHINFO.plugindir)
  for fname in lists
    if (fname.match(/^.*\.js$/))
      JSSYSLIST.push("#{SITE_NAME}/plugin/#{fname}")
  jsonsyslib = APPSJSON.additional.front.javascript
  for fname in jsonsyslib
    JSSYSLIST.push(fname)

  #----------------------------------
  # System library include
  #----------------------------------
  lists = __readFileList(PATHINFO.syslibdir)
  for fname in lists
    if (fname.match(/^.*\.min\.js$/))
      JSSYSLIST.push("#{SITE_NAME}/include/#{fname}")

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
  manifest = manifest.replace(/\[\[\[:short_name:\]\]\]/g, PKGJSON.name)
  manifest = manifest.replace(/\[\[\[:name:\]\]\]/g, PKGJSON.name)
  manifest = manifest.replace(/\[\[\[:pkgname:\]\]\]/g, PKGNAME)
  manifest = manifest.replace(/\[\[\[:background_color:\]\]\]/g, APPSJSON.site.basecolor)
  manifest = manifest.replace(/\[\[\[:display:\]\]\]/g, APPSJSON.site.pwa.display)
  manifest = manifest.replace(/\[\[\[:theme_color:\]\]\]/g, APPSJSON.site.pwa.theme_color)
  manifest = manifest.replace(/\[\[\[:orientation:\]\]\]/g, APPSJSON.site.pwa.orientation)
  fs.writeFileSync(MANIFEST_PATH, manifest, 'utf8')

#==============================================================================
# generate service worker
#==============================================================================
generateServiceworker = ->
  uri = "#{SITE_NAME}/api/__getappsinfo__"
  cache_contents_list = ["'/'", "  '#{SITE_NAME}/view/appsmain.min.js'", "  '#{SITE_NAME}/template/system.css'"]

  try
    ret = await axios.get(uri)
    JSFILELIST = ret.data.jsfilelist['userjsview']
  catch
    JSFILELIST = []

  serviceworker = fs.readFileSync(SERVICEWORKER_TMP, 'utf8')
  serviceworker = serviceworker.replace(/\[\[\[:name:\]\]\]/, PKGJSON.name)
  serviceworker = serviceworker.replace(/\[\[\[:version:\]\]\]/, PKGJSON.version)

  SYSTEMCSS = "#{SITE_NAME}/template/system.css"
  CSSFILELIST.forEach (f) =>
    cache_contents_list.push("  '#{f}'")

  JSSYSLIST.forEach (f) =>
    if (!f.match(/main\.min\.js/))
      if (f.match(/^.*:\/\//))
        cache_contents_list.push("  '#{f}'")
      else
        cache_contents_list.push("  '#{SITE_NAME}/#{f}'")

  JSFILELIST.forEach (f) =>
    cache_contents_list.push("  '#{f}'")

  cache_contents = cache_contents_list.join(",\n")
  serviceworker = serviceworker.replace(/\[\[\[:cache_contents:\]\]\]/, cache_contents)
  fs.writeFileSync(SERVICEWORKER_PATH, serviceworker, 'utf8')

#==============================================================================
# generate ICON file
#==============================================================================
generateIconFile = ->
  #------------------------
  convimage = (size, src_image, dst_path) ->
    topath = dst_path.replace(/###/g, size)
    await sharp(src_image)
      .resize
        width: size,
        height: size,
        fit: "cover"
      .toFile(topath)
    .catch (e) ->
      echo e

  #----------------------------------
  # create ICON file
  #----------------------------------
  src_image = "#{PATHINFO.libdir}/img/apps-img.png"
  try
    stats = fs.statSync(src_image)
  catch e
    src_image = "#{PATHINFO.libdir}/img/icon/icon-512x512.png"

  dst_path = "#{PATHINFO.libdir}/img/icons/icon-###x###.png"
  icon_size = [72, 96, 128, 144, 152, 192, 384, 512]

  for size in icon_size
    await convimage(size, src_image, dst_path).catch (e) ->
      echo e

  #----------------------------------
  # favicon setting
  #----------------------------------
  favicon_path = "#{PATHINFO.libdir}/img/icons/favicon.png"
  await convimage(144, src_image, favicon_path).catch (e) ->
      echo e

#==============================================================================
# startserver listen
#==============================================================================
startserver = ->
  switch (NETCONF.protocol)
    when "http"
      exphttp.listen(LISTEN_PORT)
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

#==============================================================================
# Application Initialize
#==============================================================================
appsInit = ->
  SITEJSON = APPSJSON.site || {}
  SNSJSON = APPSJSON.sns || {}

  if (NETCONF? && NETCONF.port?)
    port = NETCONF.port

  if (port == "any")
    start_port = parseInt(NETCONF.start_port) || 3000
    port = parseInt(get_free_port(start_port))

  LISTEN_PORT = port

  MANIFEST_TMP = "#{PATHINFO.templatedir}/manifest.json"
  SERVICEWORKER_TMP = "#{PATHINFO.templatedir}/serviceworker.js"

  if (NODE_ENV == "develop")
    MANIFEST_URI = "#{SITE_NAME}/lib/manifest.#{NODE_ENV}.json"
    MANIFEST_PATH = "#{PATHINFO.libdir}/manifest.#{NODE_ENV}.json"
    SERVICEWORKER_PATH = "#{PATHINFO.libdir}/serviceworker.#{NODE_ENV}.js"
  else
    MANIFEST_URI = "#{SITE_NAME}/lib/manifest.json"
    MANIFEST_PATH = "#{PATHINFO.libdir}/manifest.json"
    SERVICEWORKER_PATH = "#{PATHINFO.libdir}/serviceworker.js"

#==========================================================================
# router setting
#==========================================================================
appget = (req, res) ->
  name = req.params.name

  #----------------------------------
  # Template engine value
  #----------------------------------
  title = PKGJSON.name
  description = PKGJSON.description

  ogpimg_uri = "lib/img/OGP.png"
  twitter = ""
  facebook = ""

  #----------------------------------
  # favicon setting
  #----------------------------------
  favicon_uri = "#{SITE_NAME}/lib/img/icons/favicon.png"

  #----------------------------------
  # OGP image setting
  #----------------------------------
  if (SITEJSON? && SITEJSON.ogp?)
    ogpimg_uri = "lib/img/#{SITEJSON.ogp}"
  else
    ogpimg_uri = "lib/img/OGP.png"

  #----------------------------------
  # Production build
  #----------------------------------
  if (NODE_ENV != "develop")
    # SNS info
    if (SNSJSON?)
      img = SNSJSON.ogp || "OGP.png"
      ogpimg_uri = "lib/img/#{img}"
      twitter = SNSJSON.twitter || ""
      facebook = SNSJSON.facebook || ""
    else
      ogpimg_uri = ""
      twitter = ""
      facebook = ""

  #----------------------------------
  # Develop build
  #----------------------------------
  else
    # SNS info
    if (SNSJSON?)
      twitter = SNSJSON.twitter || ""
      facebook = SNSJSON.facebook || ""
    else
      twitter = ""
      facebook = ""

  #----------------------------------
  # rendering HTML
  #----------------------------------
  res.render "main",
    pkgname: PKGNAME
    systemcss: SYSTEMCSS
    cssfilelist: CSSFILELIST
    jssyslist: JSSYSLIST
    NODE_ENV: NODE_ENV
    ogpimg: ogpimg_uri
    favimg: favicon_uri
    title: title
    site_name: SITE_NAME
    description: description
    twitter: twitter
    facebook: facebook
    bgcolor: APPSJSON.site.basecolor
    PWA: PWA
    manifest: MANIFEST_URI
    site_width: SITE_WIDTH
    site_height: SITE_HEIGHT

#==========================================================================
# Express dispatcher
#==========================================================================
app.get "/", (req, res) ->
  SUBPATH = ""
  appget(req, res)

app.get "/:name", (req, res) ->
  name = req.params.name
  SUBPATH = "/#{name}/"
  appget(req, res)

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

module.exports = router
