#===========================================================================
# GLOBAL setting
#===========================================================================
origintmp = window.location.href.replace(/\?.*$/, "")
ORIGIN = origintmp.replace(/\/$/, "")
SITEURL = "#{ORIGIN}/#{pkgname}"
PUBLIC = "#{SITEURL}/public"
LANGUAGE = window.navigator.language
PWA = window.PWA

APPLICATION = undefined
BROWSER_FRAME = plustick.getBounds()
ROOTDIV = undefined

GLOBAL =
  PROC: {}

DEVICEORIENTATION = false

#===========================================================================
# Query parameter
#===========================================================================
querytmp = window.location.search.replace(/^\?/, "")
querylist = querytmp.split(/&/)
QUERY_PARAM = {}
querylist.forEach (str) ->
  list = str.split(/=/)
  if (list.length == 2)
    QUERY_PARAM[list[0]] = list[1]

#===========================================================================
# Resize control value
#===========================================================================
__RESIZECOUNTER__ = new Date().getTime()
__RESIZETIMEOUT__ = undefined

#===========================================================================
# super super class
#===========================================================================
class viewController
  #----------------------
  #----------------------
  constructor:(param=undefined) ->
    S4 = ->
      return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    @uniqueID = (S4()+S4()+"_"+S4()+"_"+S4()+"_"+S4()+"_"+S4()+S4()+S4())
    @browser_frame = BROWSER_FRAME
    @parent = undefined

    GLOBAL.PROC[@uniqueID] = @

  #----------------------
  #----------------------
  addView:(param) ->
    obj = param.viewobj
    id = param.id || @uniqueID
    obj.parent = @
    baseview = getElement(id) || undefined
    if (!baseview?)
      return
    else
      html = await obj.createHtml()
      baseview.insertAdjacentHTML('beforeend', html)
      obj.viewDidLoad()
      obj.viewDidAppear()

  #----------------------
  #----------------------
  removeView:(param) ->
    obj = param.viewobj || getElement(@uniqueID)
    obj.remove()
    return undefined

  #----------------------
  #----------------------
  removeDiv:(param) ->
    obj = getElement(param.id)
    obj.remove()
    return undefined

  #----------------------
  #----------------------
  createHtml: ->

  #----------------------
  #----------------------
  viewDidLoad: ->

  #----------------------
  #----------------------
  viewDidAppear: ->

#===========================================================================
# requestAnimationFrame
#===========================================================================
requestAnimationFrame = window.requestAnimationFrame ||
                        window.mozRequestAnimationFrame ||
                        window.webkitRequestAnimationFrame ||
                        window.msRequestAnimationFrame
window.requestAnimationFrame = requestAnimationFrame

#===========================================================================
# execute first process
#===========================================================================
window.addEventListener "DOMContentLoaded", ->
  #===========================================================================
  # resize event
  #===========================================================================
  window.addEventListener 'resize', ->
    if (__RESIZETIMEOUT__?)
      clearTimeout(__RESIZETIMEOUT__)
    __RESIZETIMEOUT__ = setTimeout ->
      contents_size = fitContentsSize(APPLICATION)
      ROOTDIV.style.width = "#{contents_size.width}px"
      ROOTDIV.style.height = "#{contents_size.height}px"
      ROOTDIV.style.left = "#{contents_size.left}px"
      ROOTDIV.style.top = "#{contents_size.top}px"
      list = Object.keys(GLOBAL.PROC)
      for key in list
        obj = GLOBAL.PROC[key]
        obj.resize() if (typeof(obj.resize) == "function")
      __RESIZETIMEOUT__ = undefined
    , 10

  #===========================================================================
  # fit contents size to browser
  #===========================================================================
  fitContentsSize = (apps)->
    # get browser size
    BROWSER_FRAME = plustick.getBounds()

    # get browser size
    aspect = BROWSER_FRAME.size.aspect

    if (apps.width? || apps.height?)
      contents_width = apps.width || parseInt(Math.floor(apps.height * aspect))
      contents_height = apps.height || parseInt(Math.floor(apps.width / aspect))
      apps.width = contents_width
      apps.height = contents_height

      # calc scale
      scale_x = BROWSER_FRAME.size.width / contents_width
      scale_y = BROWSER_FRAME.size.height / contents_height

      scale_mode = 1
      height_tmp = contents_height * scale_x

      if (height_tmp > BROWSER_FRAME.size.height)
        scale_mode = 2

      # calc width/height
      if (scale_mode == 1)
        real_height = parseInt(Math.floor(contents_height * scale_x))
        left = 0
        top = parseInt(Math.floor((BROWSER_FRAME.size.height - real_height) / 2))
        scale = scale_x
      else
        real_width = parseInt(Math.floor(contents_width * scale_y))
        left = parseInt(Math.floor((BROWSER_FRAME.size.width - real_width) / 2))
        top = 0
        scale = scale_y

      ROOTDIV.style.transformOrigin = "0px 0px 0px"
      ROOTDIV.style.transform = "scale(#{scale}, #{scale})"

    # does not fit contents size to browser
    else
      contents_width = BROWSER_FRAME.size.width
      contents_height = BROWSER_FRAME.size.height
      apps.width = BROWSER_FRAME.size.width
      apps.height = BROWSER_FRAME.size.height
      left = 0
      top = 0
      scale = 1.0

    BROWSER_FRAME.scale = scale
    BROWSER_FRAME.size.width = contents_width
    BROWSER_FRAME.size.height = contents_height

    return
      width: contents_width
      height: contents_height
      left: left
      top: top
      scale: scale
  #===========================================================================

  #---------------------------------------------------------------------------
  # Service Worker
  #---------------------------------------------------------------------------
  if (PWA == "activate")
    if (navigator.serviceWorker?)
      echo "serviceworker activation"
      registration = await navigator.serviceWorker.register("/serviceworker.js")
      if (typeof registration.update == 'function')
        registration.update()
      else
        PWA = "inactivate"
    else
      PWA = "inactivate"

  if (PWA == "inactivate")
    echo "Serviceworker Inactivation."

  #---------------------------------------------------------------------------
  # Gyro
  #---------------------------------------------------------------------------
  if (plustick.getBrowser().kind == "iOS")
    if (DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission == 'function')
      DeviceOrientationEvent.requestPermission().then (permissionState) ->
        if (permissionState == 'granted')
          DEVICEORIENTATION = true
  else
    DEVICEORIENTATION = true

  #---------------------------------------------------------------------------
  # plugin load
  #---------------------------------------------------------------------------

  #------------------
  # JS file loding function
  #------------------
  pluginload = (script) ->
    return new Promise (resolve, reject) ->
      head = document.getElementsByTagName('head')[0]
      try
        script.onload = (e) ->
          resolve(e)
        head.appendChild(script)
      catch e
        reject(e)

  #------------------
  # Get JS file list
  #------------------
  apiuri = "#{SITEURL}/api/__getappsinfo__"
  ret = await axios
    method: "POST"
    url: apiuri

  #------------------
  # JS file load
  #------------------
  if (ret.data.error? && ret.data.error < 0)
    return
  else
    jsfilelist = ret.data.jsfilelist['userjsview']
    pathinfo = ret.data.pathinfo
    appsjson = pathinfo.appsjson
    sitejson = appsjson.site || {}
    snsjson = appsjson.sns || {}

  #------------------
  # body setting
  #------------------
  document.body.setAttribute("id", "body")
  document.body.style.userSelect = "none"
  document.body.style.display = "none"
  document.body.style.backgroundColor = "black"

  #---------------------------------------------------------------------------
  # Splash screen
  #---------------------------------------------------------------------------
  splashimage = appsjson.site.splash.image || undefined
  splashsize = appsjson.site.splash.size || "contain"
  splash_banner = document.createElement("div")
  splash_banner.style.display = "none"
  document.body.append(splash_banner)
  contents_size = fitContentsSize(splash_banner)
  splash_banner.setAttribute("id", "splash_banner")
  splash_banner.style.position = "absolute"
  splash_banner.style.width = "#{contents_size.width}px"
  splash_banner.style.height = "#{contents_size.height}px"
  splash_banner.style.left = "#{contents_size.left}px"
  splash_banner.style.top = "#{contents_size.top}px"
  splash_banner.style.margin = "0px 0px 0px 0px"
  splash_banner.style.backgroundColor = "transparent"
  splash_banner.style.overflow = "hidden"
  splash_banner.style.backgroundSize = splashsize
  splash_banner.style.backgroundPosition = "center"
  splash_banner.style.backgroundRepeat = "no-repeat"
  splash_banner.style.backgroundAttachment = "fixed"
  if (splashimage?)
    url = "url(#{SITEURL}/lib/img/#{splashimage})"
  else
    url = "url(/splash.png)"
  splash_banner.style.backgroundImage = url
  splash_banner.style.display = "inline"

  #------------------
  # body color
  #------------------
  document.body.style.backgroundColor = sitejson.basecolor || "black"
  document.body.style.display = "inline"

  setTimeout ->
    #------------------
    # JS file load
    #------------------
    for fname in jsfilelist
      script = document.createElement("script")
      script.setAttribute("type", "text/javascript")
      script.setAttribute("src", fname)
      await pluginload(script)

    #------------------
    # disp root view
    #------------------
    splash_banner.className = "fadeout" if (splash_banner?)
    setTimeout ->
      splash_banner.remove() if (splash_banner?)

      APPLICATION = new appsmain()

      # get user setting
      backgroundColor = APPLICATION.backgroundColor || "rgba(0, 0, 0, 1.0)"

      #------------------
      # root view setting
      #------------------
      ROOTDIV = document.createElement("div")
      ROOTDIV.setAttribute("id", "ROOTDIV")
      document.body.append(ROOTDIV)

      contents_size = fitContentsSize(APPLICATION)

      ROOTDIV.style.position = "absolute"
      ROOTDIV.style.width = "#{contents_size.width}px"
      ROOTDIV.style.height = "#{contents_size.height}px"
      ROOTDIV.style.left = "#{contents_size.left}px"
      ROOTDIV.style.top = "#{contents_size.top}px"
      ROOTDIV.style.margin = "0px 0px 0px 0px"
      ROOTDIV.style.backgroundColor = backgroundColor
      ROOTDIV.style.overflow = "hidden"

      document.oncontextmenu = =>
        contextmenu = APPLICATION.contextmenu
        return contextmenu

      if (typeof APPLICATION.createHtml == 'function')
        APPLICATION.browser_frame = BROWSER_FRAME
        html = await APPLICATION.createHtml()
        ROOTDIV.insertAdjacentHTML('beforeend', html)

      if (typeof APPLICATION.viewDidLoad == 'function')
        await APPLICATION.viewDidLoad()

      if (typeof APPLICATION.viewDidAppear == 'function')
        await APPLICATION.viewDidAppear()
    , 500

  , 1000

