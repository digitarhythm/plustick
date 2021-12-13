#===========================================================================
# GLOBAL setting
#===========================================================================
origintmp = window.location.href.replace(/\?.*$/, "")
ORIGIN = origintmp.replace(/\/$/, "")
PROTOCOL = (ORIGIN.match(/(^.*?):/))[1]
SITEURL = "#{ORIGIN}/#{pkgname}"
PUBLIC = "#{SITEURL}/public"
LANGUAGE = window.navigator.language
PWA = window.PWA

APPLICATION = undefined
BROWSER_FRAME = plustick.getBounds()
ROOTDIV = undefined
SITE_WIDTH = SITE_WIDTH
SITE_HEIGHT = SITE_HEIGHT

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
    @uniqueID = "id_"+(S4()+S4()+"_"+S4()+"_"+S4()+"_"+S4()+"_"+S4()+S4()+S4())
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
  # view translation
  #----------------------
  nextView:(param) ->
    return if (!param?)

    obj = param.viewobj || undefined
    return if (!obj?)

    target = getElement(obj.uniqueID) || undefined
    return if (!target?)

    curr = getElement(APPLICATION.uniqueID)
    @removeView
      viewobj: curr

    APPLICATION = new curr()


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
      #contents_size = fitContentsSize(APPLICATION)
      #contents_size = fitContentsSize({width:APPLICATION.width,height:APPLICATION.height})
      contents_size = fitContentsSize()
      #APPLICATION.width = contents_size.width
      #APPLICATION.height = contents_size.height
      ROOTDIV.style.transformOrigin = "0px 0px 0px"
      ROOTDIV.style.transform = "scale(#{contents_size.scale}, #{contents_size.scale})"
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
  fitContentsSize = ->
    # get browser size
    BROWSER_FRAME = plustick.getBounds()

    # calc browser aspect
    aspect = BROWSER_FRAME.size.aspect

    if (SITE_WIDTH != 'any' || SITE_HEIGHT != 'any')
      if (SITE_WIDTH == 'any')
        contents_width = parseInt(Math.floor(SITE_HEIGHT * aspect))
      else
        contents_width = SITE_WIDTH

      if (SITE_HEIGHT == 'any')
        contents_height = parseInt(Math.floor(SITE_WIDTH / aspect))
      else
        contents_height = SITE_HEIGHT

      # calc scale
      scale_x = BROWSER_FRAME.size.width / contents_width
      scale_y = BROWSER_FRAME.size.height / contents_height

      height_tmp = contents_height * scale_x
      scale_mode = 1

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

    # does not fit contents size to browser
    else
      contents_width = BROWSER_FRAME.size.width
      contents_height = BROWSER_FRAME.size.height
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
      aspect: aspect

  #===========================================================================
  # plugin load
  #===========================================================================
  pluginload = (script) ->
    return new Promise (resolve, reject) ->
      head = document.getElementsByTagName('head')[0]
      try
        script.onload = (e) ->
          resolve(e)
        head.appendChild(script)
      catch e
        reject(e)

  #===========================================================================
  #===========================================================================
  #===========================================================================
  #
  # Main process
  #
  #===========================================================================
  #===========================================================================
  #===========================================================================

  #---------------------------------------------------------------------------
  # Service Worker
  #---------------------------------------------------------------------------
  if (PROTOCOL != "https")
    echo "Application is not HTTPS"
  else
    if (PWA == "activate")
      if (navigator.serviceWorker?)
        if (NODE_ENV == "develop")
          swfile = "serviceworker.develop.js"
        else
          swfile = "serviceworker.js"
        registration = await navigator.serviceWorker.register(swfile)
        if (typeof registration.update == 'function')
          registration.update()
        else
          PWA = "inactivate"
      else
        PWA = "inactivate"

    else if (PWA == "inactivate")
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

  #---------------------------------------------------------------------------
  # Splash screen
  #---------------------------------------------------------------------------
  splash_image = appsjson.site.splash.image || undefined
  splash_size = appsjson.site.splash.size || "contain"
  splash_bgcolor = appsjson.site.splash.background_color || "rgba(255, 255, 255, 1.0)"
  splash_banner = document.createElement("div")
  splash_banner.style.display = "none"
  document.body.append(splash_banner)
  contents_size = fitContentsSize()
  splash_banner.setAttribute("id", "splash_banner")
  splash_banner.style.position = "absolute"
  splash_banner.style.width = "#{contents_size.width}px"
  splash_banner.style.height = "#{contents_size.height}px"
  splash_banner.style.left = "#{contents_size.left}px"
  splash_banner.style.top = "#{contents_size.top}px"
  splash_banner.style.margin = "0px 0px 0px 0px"
  splash_banner.style.backgroundColor = splash_bgcolor
  splash_banner.style.overflow = "hidden"
  splash_banner.style.backgroundSize = splash_size
  splash_banner.style.backgroundPosition = "center"
  splash_banner.style.backgroundRepeat = "no-repeat"
  splash_banner.style.backgroundAttachment = "fixed"
  if (splash_image?)
    url = "url(#{SITEURL}/lib/img/#{splash_image})"
  else
    url = "url(/splash.png)"
  splash_banner.style.backgroundImage = url
  splash_banner.style.display = "inline"

  #------------------
  # body display
  #------------------
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
      if (APPLICATION.width?)
        SITE_WIDTH = APPLICATION.width
      if (APPLICATION.height?)
        SITE_HEIGHT = APPLICATION.height

      #------------------
      # create root view
      #------------------
      ROOTDIV = document.createElement("div")
      ROOTDIV.setAttribute("id", "ROOTDIV")
      document.body.append(ROOTDIV)

      contents_size = fitContentsSize()
      ROOTDIV.style.transformOrigin = "0px 0px 0px"
      ROOTDIV.style.transform = "scale(#{contents_size.scale}, #{contents_size.scale})"

      ROOTDIV.style.position = "absolute"
      ROOTDIV.style.width = "#{contents_size.width}px"
      ROOTDIV.style.height = "#{contents_size.height}px"
      ROOTDIV.style.left = "#{contents_size.left}px"
      ROOTDIV.style.top = "#{contents_size.top}px"
      ROOTDIV.style.margin = "0px 0px 0px 0px"
      ROOTDIV.style.overflow = "hidden"
      ROOTDIV.style.backgroundColor = "transparent"

      #------------------
      # create APPLICATION
      #------------------
      contents_size = fitContentsSize()
      #APPLICATION.width = contents_size.width
      #APPLICATION.height = contents_size.height
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

