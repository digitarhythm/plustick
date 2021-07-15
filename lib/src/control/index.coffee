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
pathinfo = require("#{__sysjsctrl}/pathinfo.min.js")

network = config.network
node_env = process.env.NODE_ENV || "production"

echo "application loading time: [#{new Date().toLocaleString("ja-JP")}]"

pkgjson = require("#{process.cwd()}/package.json")

#==========================================================================
# template engine
#==========================================================================
app.set("views", pathinfo.templatedir)
ectRenderer = ECT({ watch: true, root: pathinfo.templatedir, ext : ".ect" })
app.engine("ect", ectRenderer.render)
app.set("view engine", "ect")

#==========================================================================
# URI directory binding
#==========================================================================
app.use("/", express.static(pathinfo.rootdir))
app.use("/#{pathinfo.pkgname}/plugin", express.static(pathinfo.plugindir))
app.use("/#{pathinfo.pkgname}/stylesheet", express.static(pathinfo.stylesheetdir))
app.use("/#{pathinfo.pkgname}/public", express.static(pathinfo.publicdir))
app.use("/#{pathinfo.pkgname}/view", express.static(pathinfo.usrjsview))
app.use("/#{pathinfo.pkgname}/syslib", express.static(pathinfo.sysjsview))
app.use("/#{pathinfo.pkgname}/include", express.static(pathinfo.syslibdir))
app.use("/#{pathinfo.pkgname}/template", express.static(pathinfo.templatedir))

#==========================================================================
# routing function dictionary
#==========================================================================
global.BIND_ROUTER = {}
global.APPSDIR = pathinfo.homedir
global.PLUSTICKLIBS = pathinfo.sysjsctrl

#==========================================================================
# user API binding
#==========================================================================
api = require("#{pathinfo.sysjsctrl}/sysapi.min.js")
app.use("/#{pathinfo.pkgname}/api", api)

#==========================================================================
# setting import
#==========================================================================
appsjson = require("#{pathinfo.homedir}/config/application.json")
sysjson = require("#{pathinfo.systemdir}/lib/config/system.json")
sitejson = appsjson.site || {}
snsjson = appsjson.sns || {}
manifest_tmp = "#{pathinfo.templatedir}/manifest.json"
manifest_uri = "/#{pathinfo.pkgname}/public/manifest.json"
manifest_path = "#{pathinfo.publicdir}/manifest.json"
serviceworker_tmp = "#{pathinfo.templatedir}/serviceworker.js"
serviceworker_path = "#{pathinfo.rootdir}/serviceworker.js"

#==========================================================================
# Site info
#==========================================================================
if (sitejson?)
  site_origin = sitejson.origin || ""
else
  site_origin = ""

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
# user API import
#==========================================================================
lists = __readFileList(pathinfo.usrctrldir)
for fname in lists
  if (fname.match(/^.*\.js$/))
    require "/#{pathinfo.usrctrldir}/#{fname}"

#==========================================================================
# make directory file list
#==========================================================================
cssfilelist = [].concat(sysjson.additional.front.css) || []
cssfilelist = cssfilelist.concat(appsjson.additional.front.css)
jssyslist = [].concat(sysjson.additional.front.javascript) || []
jssyslist = jssyslist.concat(appsjson.additional.front.javascript)

#----------------------------------
# System link file
#----------------------------------
systemcss = "#{pathinfo.pkgname}/template/system.css"

#----------------------------------
# User CSS file include
#----------------------------------
lists = __readFileList(pathinfo.stylesheetdir)
for fname in lists
  if (fname.match(/^.*\.css$/))
    cssfilelist.push("#{pathinfo.pkgname}/stylesheet/#{fname}")

#----------------------------------
# User plugin include
#----------------------------------
lists = __readFileList(pathinfo.plugindir)
for fname in lists
  if (fname.match(/^.*\.js$/))
    jssyslist.push("#{pathinfo.pkgname}/plugin/#{fname}")

#----------------------------------
# System library include
#----------------------------------
lists = __readFileList(pathinfo.syslibdir)
for fname in lists
  if (fname.match(/^.*\.min\.js$/))
    jssyslist.push("#{pathinfo.pkgname}/include/#{fname}")

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
  start_url = if (appsjson.site.pwa.start_url == "") then config.network.start_url else appsjson.site.pwa.start_url
  manifest = fs.readFileSync(manifest_tmp, 'utf8')
  manifest = manifest.replace(/\[\[\[:short_name:\]\]\]/, pkgjson.name)
  manifest = manifest.replace(/\[\[\[:name:\]\]\]/, pkgjson.name)
  manifest = manifest.replace(/\[\[\[:start_url:\]\]\]/, start_url)
  manifest = manifest.replace(/\[\[\[:display:\]\]\]/, appsjson.site.pwa.display)
  manifest = manifest.replace(/\[\[\[:theme_color:\]\]\]/, appsjson.site.pwa.theme_color)
  manifest = manifest.replace(/\[\[\[:background_color:\]\]\]/, appsjson.site.pwa.background_color)
  manifest = manifest.replace(/\[\[\[:orientation:\]\]\]/, appsjson.site.pwa.orientation)
  fs.writeFileSync(manifest_path, manifest, 'utf8')

#==============================================================================
# generate service worker
#==============================================================================
generateServiceworker = ->
  uri = "#{site_origin}/#{pathinfo.pkgname}/api/__getappsinfo__"
  ret = await axios.get(uri)
  jsfilelist = ret.data.jsfilelist

  serviceworker = fs.readFileSync(serviceworker_tmp, 'utf8')
  serviceworker = serviceworker.replace(/\[\[\[:name:\]\]\]/, pkgjson.name)
  serviceworker = serviceworker.replace(/\[\[\[:version:\]\]\]/, pkgjson.version)

  cache_contents_list = ["\"/\"", "  \"/#{pathinfo.pkgname}/template/system.css\""]

  cssfilelist.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  jssyslist.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  jsfilelist = ret.data.jsfilelist
  jsfilelist.forEach (f) =>
    cache_contents_list.push("  \"/#{f}\"")

  cache_contents = cache_contents_list.join(",\n")
  serviceworker = serviceworker.replace(/\[\[\[:cache_contents:\]\]\]/, cache_contents)
  fs.writeFileSync(serviceworker_path, serviceworker, 'utf8')

#==============================================================================
# generate ICON file
#==============================================================================
generateIconFile = ->
  imgpath = "#{pathinfo.publicdir}/img/OGP.png"
  pathtmp = "#{pathinfo.publicdir}/img/icons/icon-###x###.png"
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
  if (config.network? && config.network.port?)
    port = config.network.port

  if (port == "any")
    start_port = parseInt(config.network.start_port) || 3000
    port = parseInt(get_free_port(start_port))

  switch (config.network.protocol)
    when "http"
      await exphttp.listen(port)
      console.log("listening HTTP:", port)

    when "https"
      app.use (req, res, next) ->
        if (!req.secure)
          res.redirect(301, 'https://' + req.hostname + ':port' + req.originalUrl)
        next()
      options =
        key: fs.readFileSync(config.network.ssl_key)
        cert: fs.readFileSync(config.network.ssl_cert)
      httpolyglot.createServer(options, app).listen(port)
      console.log("listening HTTP/HTTPS:", port)

  module.exports = router

#==========================================================================
# router setting
#==========================================================================
app.get "/", (req, res) ->
  #----------------------------------
  # Template engine value
  #----------------------------------
  title = pkgjson.name
  site_name = pkgjson.name
  description = pkgjson.description

  #----------------------------------
  # Production build
  #----------------------------------
  if (node_env == "production")
    # Site info
    if (sitejson?)
      favimg = sitejson.favicon || ""
    else
      favimg = ""

    # SNS info
    if (snsjson?)
      ogpimg = snsjson.ogp || "OGP.png"
      twitter = snsjson.twitter || ""
      facebook = snsjson.facebook || ""
    else
      ogpimg = ""
      twitter = ""
      facebook = ""
  else
    favimg = sitejson.favicon || ""
    ogpimg = snsjson.ogp || "OGP.png"
    twitter = snsjson.twitter || ""
    facebook = snsjson.facebook || ""

  #----------------------------------
  # rendering HTML
  #----------------------------------
  res.render "main",
    pkgname: pathinfo.pkgname
    systemcss: systemcss
    cssfilelist: cssfilelist
    jssyslist: jssyslist
    node_env: node_env
    origin: site_origin
    ogpimg: ogpimg
    favimg: favimg
    title: title
    site_name: site_name
    description: description
    twitter: twitter
    facebook: facebook
    manifest: manifest_uri

#==========================================================================
# execute modules
#==========================================================================
generateManifest()
generateServiceworker()
generateIconFile()
startserver()

