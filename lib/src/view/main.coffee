#===========================================================================
# GLOBAL setting
#===========================================================================
origintmp = window.location.href.replace(/\?.*$/, "")
ORIGIN = origintmp.replace(/\/$/, "")
SITEURL = "#{ORIGIN}/#{pkgname}"
querytmp = window.location.search.replace(/^\?/, "")
querylist = querytmp.split(/&/)
QUERY_PARAM = {}
querylist.forEach (str) ->
  list = str.split(/=/)
  if (list.length == 2)
    QUERY_PARAM[list[0]] = list[1]
PUBLIC = "#{SITEURL}/public"
APPLICATION = undefined
BROWSER_FRAME = undefined
ROOT = undefined
GLOBAL =
  PROC: {}

__RESIZECOUNTER__ = new Date().getTime()
__RESIZETIMEOUT__ = undefined

#===========================================================================
# super super class
#===========================================================================
class coreobject
  constructor: (param=undefined) ->
    @visibility = false
    @selfdiv = undefined

    size = {}
    origin = {}
    if (param? && param.frame?)
      if (param.frame.size?)
        size.width = param.frame.size.width || undefined
        size.height = param.frame.size.height || undefined
      if (param.frame.origin?)
        origin.x = param.frame.origin.x || undefined
        origin.y = param.frame.origin.y || undefined

    @__frame__ =
      origin:
        x: origin.x || undefined
        y: origin.y || undefined
      size:
        width: size.width || undefined
        height: size.height || undefined

    S4 = ->
      return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    @uniqueID = (S4()+S4()+"_"+S4()+"_"+S4()+"_"+S4()+"_"+S4()+S4()+S4())

    GLOBAL.PROC[@uniqueID] = @

  addView:(obj, baseid=@uniqueID) ->
    obj.parent = @
    obj.browser_frame = BROWSER_FRAME
    baseview = getElement(baseid) || undefined
    if (!baseview?)
      return
    else
      html = await obj.createHtml()
      ret = baseview.insertAdjacentHTML('beforeend', html)
      obj.viewDidLoad()
      obj.viewDidAppear()

  removeView:(removeid) ->
    obj = getElement(removeid)
    obj.remove()
    return undefined

  createHtml: ->
    return "<div></div>"

  viewDidLoad: ->
    @selfdiv = getElement(@uniqueID) || undefined

    if (@selfdiv?)
      @selfdiv.style.width = "#{@__frame__.size.width}px" if (@__frame__.size.widt?)
      @selfdiv.style.height = "#{@__frame__.size.height}px" if (@__frame__.size.height?)
      @selfdiv.style.left = "#{@__frame__.origin.x}px" if (@__frame__.origin.x?)
      @selfdiv.style.top = "#{@__frame__.origin.y}px" if (@__frame__.origin.y?)
    @__frame__ = undefined

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
      ROOT.style.width = "#{contents_size.width}px"
      ROOT.style.height = "#{contents_size.height}px"
      ROOT.style.left = "#{contents_size.left}px"
      ROOT.style.top = "#{contents_size.top}px"
      BROWSER_FRAME.style.width = "#{contents_size.width}px"
      BROWSER_FRAME.style.height = "#{contents_size.height}px"
      BROWSER_FRAME.style.left = "#{contents_size.left}px"
      BROWSER_FRAME.style.top = "#{contents_size.top}px"
      list = Object.keys(GLOBAL.PROC)
      for key in list
        obj = GLOBAL.PROC[key]
        obj.resize() if (typeof(obj.resize) == "function")
      __RESIZETIMEOUT__ = undefined
    , 100

  #===========================================================================
  # fit contents size to browser
  #===========================================================================
  fitContentsSize = (apps)->
    # get browser size
    BROWSER_FRAME = plustick.getBounds()

    # get browser size
    browser_aspect = BROWSER_FRAME.size.width / BROWSER_FRAME.size.height

    if (apps.width? || apps.height?)
      contents_width = apps.width || parseInt(Math.round(apps.height * browser_aspect))
      contents_height = apps.height || parseInt(Math.round(apps.width / browser_aspect))
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

      ROOT.style.transformOrigin = "0px 0px 0px"
      ROOT.style.transform = "scale(#{scale}, #{scale})"

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
  bodybgcolor = APPLICATION.bodyBackgroundColor || "rgba(64, 64, 64, 1.0)"

  # body setting
  document.body.setAttribute("id", "body")
  document.body.style.userSelect = "none"
  document.body.style.backgroundColor = bodybgcolor
  document.oncontextmenu = =>
    contextmenu = APPLICATION.contextmenu
    return contextmenu

  # create root view
  ROOT = document.createElement("div")
  ROOT.setAttribute("id", "__rootview__")
  document.body.append(ROOT)

  contents_size = fitContentsSize(APPLICATION)

  ROOT.style.position = "absolute"
  ROOT.style.width = "#{contents_size.width}px"
  ROOT.style.height = "#{contents_size.height}px"
  ROOT.style.left = "#{contents_size.left}px"
  ROOT.style.top = "#{contents_size.top}px"

  ROOT.style.margin = "0px 0px 0px 0px"
  ROOT.style.backgroundColor = backgroundColor
  ROOT.style.overflow = "hidden"

  if (typeof APPLICATION.createHtml == 'function')
    html = await APPLICATION.createHtml()
    if (html?)
      display = ROOT.style.display
      ROOT.style.display = "none"
      ROOT.innerHTML = html

    if (typeof APPLICATION.viewDidLoad == 'function')
      await APPLICATION.viewDidLoad()

    ROOT.style.display = display

    if (typeof APPLICATION.viewDidAppear == 'function')
      await APPLICATION.viewDidAppear()

