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

pkgjson = require("#{process.cwd()}/package.json")
pkgname = pkgjson.name
network = config.network
node_env = process.env.NODE_ENV || "production"

echo "application loading time: [#{new Date().toLocaleString("ja-JP")}]"

# system directory
__systemdir = fs.realpathSync(__dirname+"/../../..")

# home directory
__homedir = fs.realpathSync(__dirname+"/../../../../..")

# application directory
__appsdir = "#{__homedir}/apps"

# public directory
__publicdir = "#{__appsdir}/public"

# tmpl directory
__templatedir = "#{__systemdir}/lib/template"

# plugin directory
__plugindir = "#{__appsdir}/plugin"

# javascript directory
__jsdir = "#{__appsdir}/js"
__jsctrldir = "#{__jsdir}/control"
__jsviewdir = "#{__jsdir}/view"

# user library directory
__usrlibsdir = "#{__appsdir}/js"
__usrctrldir = "#{__usrlibsdir}/control"
__usrviewdir = "#{__usrlibsdir}/view"

# system library directory
__syslibsdir = "#{__systemdir}/lib/js"
__syslibsctrl = "#{__syslibsdir}/control"
__syslibsview = "#{__syslibsdir}/view"

#==========================================================================
# template engine
#==========================================================================
app.set("views", __templatedir)
ectRenderer = ECT({ watch: true, root: __templatedir, ext : ".ect" })
app.engine("ect", ectRenderer.render)
app.set("view engine", "ect")

#==========================================================================
# URI directory binding
#==========================================================================
app.use("/#{pkgname}/plugin", express.static(__plugindir))
app.use("/#{pkgname}/public", express.static(__publicdir))
app.use("/#{pkgname}/view", express.static(__jsviewdir))
app.use("/#{pkgname}/syslib", express.static(__syslibsview))

#==========================================================================
# routing function dictionary
#==========================================================================
global.BIND_ROUTER = {}
global.APPSDIR = __homedir
global.PLUSTICKLIBS = __syslibsctrl

#==========================================================================
# user API binding
#==========================================================================
api = require("#{__syslibsctrl}/sysapi.min.js")
app.use("/#{pkgname}/api", api)

#==========================================================================
# setting import
#==========================================================================
appjson = require("#{__homedir}/config/application.json")
sysjson = require("#{__systemdir}/lib/config/system.json")

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
__readFileList(__usrctrldir).then (lists) ->
	for fname in lists
		if (fname.match(/^.*\.js$/))
			require "/#{__usrctrldir}/#{fname}"

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

  __readFileList(__plugindir).then (lists) ->
    # JS/CSS file in plugin directory
    for fname in lists
      if (fname.match(/^.*\.css$/))
        cssfilelist.push("#{pkgname}/plugin/#{fname}")
      if (fname.match(/^.*\.js$/))
        jssyslist.push("#{pkgname}/plugin/#{fname}")
    return 1

  .then (ret) ->
    # JS file in user script directory
    __readFileList(__jsviewdir).then (lists) ->
      filelist = []
      for fname in lists
        if (fname.match(/^.*\.min\.js$/) and !fname.match(/^main\.min\.js/) and !fname.match(/^plustick\.min\.js/))
          jsuserlist.push("#{pkgname}/view/#{fname}")
      return 1

  .then (ret) ->
    origin=config.Author.url
    title=pkgjson.name
    site_name=pkgjson.name
    description=pkgjson.description
    thumbnail="#{config.Author.url}/#{pkgname}/public/OGP.png"
    twitter = config.Author.twitter || ""
    facebook = config.Author.facebook || ""
    # rendering HTML
    res.render "main",
      pkgname: pkgname
      jssyslist: jssyslist
      jsuserlist: jsuserlist
      cssfilelist: cssfilelist
      node_env: node_env
      origin: origin
      title: title
      site_name: site_name
      description: description
      thumbnail: thumbnail
      twitter: twitter
      facebook: facebook
  .catch (err) ->
    console.error(err)
    process.exit(1)

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

