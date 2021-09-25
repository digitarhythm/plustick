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
global.HOMEDIR = PATHINFO.homedir
global.APPSDIR = PATHINFO.appsdir
global.PLUSTICKLIBS = PATHINFO.sysjsctrl

#----------------------------------
# global value
#----------------------------------
APPSJSON = require("#{PATHINFO.appsdir}/config/application.json")
SYSJSON = require("#{PATHINFO.systemdir}/lib/config/system.json")
SYSAPI = require("#{PATHINFO.sysjsctrl}/sysapi.min.js")
PKGJSON = require("#{process.cwd()}/package.json")

NODE_ENV = process.env.NODE_ENV || "production"
START_URL = undefined
SITE_URL = undefined
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

PKGNAME = PATHINFO.pkgname
PWA = if (APPSJSON.site.pwa.installed == true) then "activate" else "inactivate"

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
  app.use("/", express.static(PATHINFO.libdir))
  app.use("/#{PKGNAME}/plugin", express.static(PATHINFO.plugindir))
  app.use("/#{PKGNAME}/stylesheet", express.static(PATHINFO.stylesheetdir))
  app.use("/#{PKGNAME}/public", express.static(PATHINFO.publicdir))
  app.use("/#{PKGNAME}/view", express.static(PATHINFO.usrjsview))
  app.use("/#{PKGNAME}/lib", express.static(PATHINFO.libdir))
  app.use("/#{PKGNAME}/syslib", express.static(PATHINFO.sysjsview))
  app.use("/#{PKGNAME}/include", express.static(PATHINFO.syslibdir))
  app.use("/#{PKGNAME}/template", express.static(PATHINFO.templatedir))
  app.use("/#{PKGNAME}/api", SYSAPI)

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
      CSSFILELIST.push("#{PKGNAME}/stylesheet/#{fname}")

  #----------------------------------
  # User plugin include
  #----------------------------------
  lists = __readFileList(PATHINFO.plugindir)
  for fname in lists
    if (fname.match(/^.*\.js$/))
      JSSYSLIST.push("#{PKGNAME}/plugin/#{fname}")

  #----------------------------------
  # System library include
  #----------------------------------
  lists = __readFileList(PATHINFO.syslibdir)
  for fname in lists
    if (fname.match(/^.*\.min\.js$/))
      JSSYSLIST.push("#{PKGNAME}/include/#{fname}")

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
  manifest = manifest.replace(/\[\[\[:start_url:\]\]\]/g, START_URL)
  manifest = manifest.replace(/\[\[\[:display:\]\]\]/g, APPSJSON.site.pwa.display)
  manifest = manifest.replace(/\[\[\[:theme_color:\]\]\]/g, APPSJSON.site.pwa.theme_color)
  manifest = manifest.replace(/\[\[\[:background_color:\]\]\]/g, APPSJSON.site.pwa.background_color)
  manifest = manifest.replace(/\[\[\[:orientation:\]\]\]/g, APPSJSON.site.pwa.orientation)
  manifest = manifest.replace(/\[\[\[:pkgname:\]\]\]/g, PKGNAME)
  fs.writeFileSync(MANIFEST_PATH, manifest, 'utf8')

#==============================================================================
# generate service worker
#==============================================================================
generateServiceworker = ->
  uri = "#{START_URL}/#{PKGNAME}/api/__getappsinfo__"

  try
    ret = await axios.get(uri)
    JSFILELIST = ret.data.jsfilelist['userjsview']
  catch
    JSFILELIST = []

  serviceworker = fs.readFileSync(SERVICEWORKER_TMP, 'utf8')
  serviceworker = serviceworker.replace(/\[\[\[:name:\]\]\]/, PKGJSON.name)
  serviceworker = serviceworker.replace(/\[\[\[:version:\]\]\]/, PKGJSON.version)

  cache_contents_list = ["\"/\"", "  \"/#{PKGNAME}/template/system.css\""]

  CSSFILELIST.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  JSSYSLIST.forEach (f) =>
    if (!f.match(/main\.min\.js/))
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

  #------------------------

  src_image = "#{PATHINFO.libdir}/img/icons/apps-img.png"
  try
    stats = fs.statSync(src_image)
  catch e
    src_image = "#{PATHINFO.templatedir}/apps-img.png"

  dst_path = "#{PATHINFO.libdir}/img/icons/icon-###x###.png"
  icon_size = [72, 96, 128, 144, 152, 192, 384, 512]

  for size in icon_size
    await convimage(size, src_image, dst_path).catch (e) ->
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
  SYSTEMCSS = "#{PKGNAME}/template/system.css"
  SITEJSON = APPSJSON.site || {}
  SNSJSON = APPSJSON.sns || {}

  MANIFEST_TMP = "#{PATHINFO.templatedir}/manifest.json"
  SERVICEWORKER_TMP = "#{PATHINFO.templatedir}/serviceworker.js"

  MANIFEST_URI = "#{PKGNAME}/lib/manifest.#{NODE_ENV}.json"
  MANIFEST_PATH = "#{PATHINFO.libdir}/manifest.#{NODE_ENV}.json"
  SERVICEWORKER_PATH = "#{PATHINFO.libdir}/serviceworker.#{NODE_ENV}.js"

  if (NETCONF? && NETCONF.port?)
    port = NETCONF.port

  if (port == "any")
    start_port = parseInt(NETCONF.start_port) || 3000
    port = parseInt(get_free_port(start_port))

  LISTEN_PORT = port
  if (config.application.start_url?)
    START_URL = config.application.start_url
  else
    START_URL = "http://localhost:#{LISTEN_PORT}"
  SITE_URL = "#{START_URL}/#{PKGNAME}"

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

  favicon_uri = ""
  ogpimg_uri = "img/OGP.png"
  twitter = ""
  facebook = ""

  #----------------------------------
  # Production build
  #----------------------------------
  if (NODE_ENV == "production")
    # Site info
    if (SITEJSON?)
      if (SITEJSON.favicon? && SITEJSON.favicon != "")
        favicon_uri = "#{SITE_URL}/lib/img/icons/#{SITEJSON.favicon}"
      else
        favicon_uri = "#{SITE_URL}/lib/img/icons/icon-144x144.png"

    # SNS info
    if (SNSJSON?)
      img = SNSJSON.ogp || "OGP.png"
      ogpimg_uri = "img/#{img}"
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
    # Site info
    if (SITEJSON?)
      if (START_URL != "")
        if (SITEJSON.favicon? && SITEJSON.favicon != "")
          favicon_uri = "#{SITE_URL}/lib/img/icons/#{SITEJSON.favicon}"
        else
          favicon_uri = "#{SITE_URL}/lib/img/icons/icon-144x144.png"
      else
        favicon_uri = ""

      if (SITEJSON.ogp?)
        ogpimg_uri = "img/#{SITEJSON.ogp}"
      else
        ogpimg_uri = "img/OGP.png"

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
    origin: START_URL
    site_url: SITE_URL
    ogpimg: ogpimg_uri
    favimg: favicon_uri
    title: title
    site_name: site_name
    description: description
    twitter: twitter
    facebook: facebook
    PWA: PWA
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

module.exports = router
