#===========================================================================
# GLOBAL setting
#===========================================================================
origintmp = window.location.href.replace(/\?.*$/, "")
ORIGIN = origintmp.replace(/\/$/, "")
SITEURL = "#{ORIGIN}/#{pkgname}"
PUBLIC = "#{SITEURL}/public"
LANGUAGE = window.navigator.language

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
  constructor: (param=undefined) ->
    S4 = ->
      return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    @uniqueID = (S4()+S4()+"_"+S4()+"_"+S4()+"_"+S4()+"_"+S4()+S4()+S4())
    @browser_frame = BROWSER_FRAME

    GLOBAL.PROC[@uniqueID] = @

  #----------------------
  #----------------------
  addView:(obj, baseid=@uniqueID) ->
    obj.parent = @
    baseview = getElement(baseid) || undefined
    if (!baseview?)
      return
    else
      html = await obj.createHtml()
      baseview.insertAdjacentHTML('beforeend', html)
      obj.viewDidLoad()
      obj.viewDidAppear()

  #----------------------
  #----------------------
  removeView:(obj) ->
    obj = getElement(@uniqueID)
    obj.remove()
    return undefined

  #----------------------
  #----------------------
  removeDiv:(removeid) ->
    obj = getElement(removeid)
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
window.onload =  ->
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
      contents_width = apps.width || parseInt(Math.round(apps.height * aspect))
      contents_height = apps.height || parseInt(Math.round(apps.width / aspect))
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
        real_height = contents_height * scale_x
        left = 0
        top = parseInt(Math.floor((BROWSER_FRAME.size.height - real_height) / 2))
        scale = scale_x
      else
        real_width = contents_width * scale_y
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

    return
      width: contents_width
      height: contents_height
      left: left
      top: top
  #===========================================================================

  # create application main
  APPLICATION = new appsmain()

  # get user setting
  backgroundColor = APPLICATION.backgroundColor || "rgba(0, 0, 0, 1.0)"
  bodybgcolor = APPLICATION.bodyBackgroundColor || "rgba(32, 32, 32, 1.0)"

  # body setting
  document.body.setAttribute("id", "body")
  document.body.style.userSelect = "none"
  document.body.style.backgroundColor = bodybgcolor
  document.oncontextmenu = =>
    contextmenu = APPLICATION.contextmenu
    return contextmenu

  # root view setting
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
  # disp root view
  #---------------------------------------------------------------------------
  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.browser_frame = BROWSER_FRAME
    html = await APPLICATION.createHtml()
    ROOTDIV.insertAdjacentHTML('beforeend', html)

  if (typeof APPLICATION.viewDidLoad == 'function')
    await APPLICATION.viewDidLoad()

  if (typeof APPLICATION.viewDidAppear == 'function')
    await APPLICATION.viewDidAppear()

