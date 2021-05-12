express = require("express")
router = express.Router()
app = express()
Promise = require("bluebird")
execSync = require("child_process").execSync
exphttp = require("http").Server(app)
https = require("https")
path = require("path")
config = require("config")
fs = require("fs-extra")
echo = require("ndlog").echo
process = require("process")
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
app.use("/#{pathinfo.pkgname}/plugin", express.static(pathinfo.plugindir))
app.use("/#{pathinfo.pkgname}/stylesheet", express.static(pathinfo.stylesheetdir))
app.use("/#{pathinfo.pkgname}/public", express.static(pathinfo.publicdir))
app.use("/#{pathinfo.pkgname}/view", express.static(pathinfo.usrjsview))
app.use("/#{pathinfo.pkgname}/syslib", express.static(pathinfo.sysjsview))
app.use("/#{pathinfo.pkgname}/usrlib", express.static(pathinfo.usrlibdir))
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
appjson = require("#{pathinfo.homedir}/config/application.json")
sysjson = require("#{pathinfo.systemdir}/lib/config/system.json")

#==========================================================================
# read file list function
#==========================================================================
__readFileList = (path) ->
	return new Promise (resolve, reject) ->
		fs.readdir path, (err, lists) ->
			if (err)
				reject(err)
			else
				resolve(lists)

#==========================================================================
# user API import
#==========================================================================
usrliblist = []
__readFileList(pathinfo.usrctrldir).then (lists) ->
	for fname in lists
		if (fname.match(/^.*\.js$/))
			require "/#{pathinfo.usrctrldir}/#{fname}"

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

#==========================================================================
# router setting
#==========================================================================
app.get "/", (req, res) ->
  #==========================================================================
  # make directory file list
  #==========================================================================
  cssfilelist = [].concat(sysjson.additional.front.css) || []
  cssfilelist.push(...appjson.additional.front.css)

  jssyslist = [].concat(sysjson.additional.front.javascript) || []
  jssyslist.push(...appjson.additional.front.javascript)

  jsuserlist = []

  #----------------------------------
  # System CSS file
  #----------------------------------
  systemcss = "#{pathinfo.pkgname}/template/system.css"

  #----------------------------------
  # User CSS file include
  #----------------------------------
  lists = await __readFileList(pathinfo.stylesheetdir)
  for fname in lists
    if (fname.match(/^.*\.css$/))
      cssfilelist.push("#{pathinfo.pkgname}/stylesheet/#{fname}")

  #----------------------------------
  # Template engine value
  #----------------------------------
  title = pkgjson.name
  site_name = pkgjson.name
  description = pkgjson.description

  #----------------------------------
  # SNS Info
  #----------------------------------
  if (appjson.site?)
    origin = "#{(appjson.site.origin || req.headers.host)}"
    ogpimg = appjson.site.image || ""
    favimg = appjson.site.favicon || ""
    twitter = appjson.site.twitter || ""
    facebook = appjson.site.facebook || ""
  else
    origin = req.headers.host
    ogpimg = ""
    favimg = ""
    twitter = ""
    facebook = ""

  #----------------------------------
  # rendering HTML
  #----------------------------------
  res.render "main",
    pkgname: pathinfo.pkgname
    systemcss: systemcss
    cssfilelist: cssfilelist
    node_env: node_env
    origin: origin
    ogpimg: ogpimg
    favimg: favimg
    title: title
    site_name: site_name
    description: description
    twitter: twitter
    facebook: facebook

#==============================================================================
# run server
#==============================================================================
if (config.network? && config.network.port?)
  port = config.network.port

if (port == "any")
  startport = parseInt(config.network.startport) || 3000
  port = parseInt(get_free_port(startport))

switch (config.network.protocol)
  when "http"
    exphttp.listen port, ->
      console.log("listening on *:", port)
  when "https"
    options =
      key: fs.readFileSync(config.network.ssl_key)
      cert: fs.readFileSync(config.network.ssl_cert)
    server = https.createServer(options, app)
    server.listen(port)
    console.log("listening on *:", port)

module.exports = router

