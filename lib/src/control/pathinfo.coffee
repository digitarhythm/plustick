fs = require("fs-extra")
process = require("process")
pkgjson = require("#{process.cwd()}/package.json")

# Application JSON
__appsjson = require("#{process.cwd()}/config/application.json")
# Package name
__pkgname = pkgjson.name
# System directory
__systemdir = fs.realpathSync(__dirname+"/../../..")
# home directory
__homedir = fs.realpathSync("./")
# application directory
__appsdir = "#{__homedir}/apps"
# root directory
__rootdir = "#{__appsdir}/public"
# public directory
__publicdir = "#{__appsdir}/public"
# tmpl directory
__templatedir = "#{__systemdir}/lib/template"
# plugin directory
__plugindir = "#{__appsdir}/plugin"
# stylesheet directory
__stylesheetdir = "#{__appsdir}/stylesheet"
# javascript directory
__usrjsdir = "#{__appsdir}/js"
__usrjsctrl = "#{__usrjsdir}/control"
__usrjsview = "#{__usrjsdir}/view"
# user JavaScript directory
__usrjssdir = "#{__appsdir}/js"
__usrctrldir = "#{__usrjssdir}/control"
__usrviewdir = "#{__usrjssdir}/view"
# system file directory
__sysjsdir = "#{__systemdir}/lib/js"
__sysjsctrl = "#{__sysjsdir}/control"
__sysjsview = "#{__sysjsdir}/view"
# system library directory
__syslibdir = "#{__systemdir}/lib/include"

exports.appsjson      = __appsjson
exports.pkgname       = __pkgname
exports.systemdir     = __systemdir
exports.homedir       = __homedir
exports.appsdir       = __appsdir
exports.rootdir       = __rootdir
exports.publicdir     = __publicdir
exports.templatedir   = __templatedir
exports.plugindir     = __plugindir
exports.stylesheetdir = __stylesheetdir
exports.usrjsdir      = __usrjsdir
exports.usrjsctrl     = __usrjsctrl
exports.usrjsview     = __usrjsview
exports.usrjssdir     = __usrjssdir
exports.usrctrldir    = __usrctrldir
exports.usrviewdir    = __usrviewdir
exports.sysjsdir      = __sysjsdir
exports.sysjsctrl     = __sysjsctrl
exports.sysjsview     = __sysjsview
exports.syslibdir     = __syslibdir

