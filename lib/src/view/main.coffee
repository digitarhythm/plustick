#===========================================================================
# GLOBAL setting
#===========================================================================
ORIGIN = window.location.href.replace(/\/$/, "")+"/#{pkgname}"
PUBLIC = "#{ORIGIN}/public"
APPLICATION = undefined
ROOT = undefined
GLOBAL =
  PROC: {}

#===========================================================================
# super super class
#===========================================================================
class coreobject
  constructor: ->
    S4 = ->
      return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    @uniqueID = (S4()+S4()+"_"+S4()+"_"+S4()+"_"+S4()+"_"+S4()+S4()+S4())
    GLOBAL.PROC[@uniqueID] = @
    if (APPLICATION?)
      @width = APPLICATION.width
      @height = APPLICATION.height

  addView:(id, obj) ->
    target = getElement(id) || undefined
    if (!target?)
      return
    else
      html = await obj.createHtml()
      backup = target.style.display
      target.style.display = "none"
      target.insertAdjacentHTML('beforeend', html)
      obj.viewDidLoad()
      target.style.display = backup
      obj.viewDidAppear()

  createHtml: ->

  viewDidLoad: ->

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
  # create application main
  APPLICATION = new appsmain()

  # get browser size
  bounds = plustick.getBounds()
  browser_width = bounds.size.width
  browser_height = bounds.size.height
  browser_aspect = browser_width / browser_height

  # get user setting
  backgroundColor = APPLICATION.backgroundColor || "rgba(0, 0, 0, 1.0)"

  # body setting
  document.body.setAttribute("id", "body")
  document.body.style.userSelect = "none"
  document.oncontextmenu = =>
    contextmenu = APPLICATION.contextmenu
    return contextmenu

  # create root view
  ROOT = document.createElement("div")
  ROOT.setAttribute("id", "__rootview__")
  document.body.append(ROOT)

  ROOT.width = browser_width
  ROOT.height = browser_height

  # resize event
  window.addEventListener 'resize', ->
    bounds = plustick.getBounds()
    ROOT.width = bounds.size.width
    ROOT.height = bounds.size.height

  # fit contents size to browser
  if (APPLICATION.width? || APPLICATION.height?)
    contents_width = APPLICATION.width || parseInt(Math.round(APPLICATION.height * browser_aspect))
    contents_height = APPLICATION.height || parseInt(Math.round(APPLICATION.width / browser_aspect))
    APPLICATION.width = contents_width
    APPLICATION.height = contents_height

    # browser resolution
    bounds = plustick.getBounds()
    browser_width = bounds.size.width
    browser_height = bounds.size.height

    # calc scale
    scale_x = browser_width / contents_width
    scale_y = browser_height / contents_height

    scale_mode = 1
    height_tmp = contents_height * scale_x

    if (height_tmp > browser_height)
      scale_mode = 2

    # calc width/height
    if (scale_mode == 1)
      real_height = contents_height * scale_x
      left = 0
      top = parseInt(Math.floor((browser_height - real_height) / 2))
      scale = scale_x
    else
      real_width = contents_width * scale_y
      left = parseInt(Math.floor((browser_width - real_width) / 2))
      top = 0
      scale = scale_y

    ROOT.style.transformOrigin = "0px 0px 0px"
    ROOT.style.transform = "scale(#{scale}, #{scale})"

  # does not fit contents size to browser
  else
    contents_width = browser_width
    contents_height = browser_height
    APPLICATION.width = browser_width
    APPLICATION.height = browser_height
    left = 0
    top = 0

  ROOT.style.position = "absolute"
  ROOT.style.width = "#{contents_width}px"
  ROOT.style.height = "#{contents_height}px"
  ROOT.style.left = "#{left}px"
  ROOT.style.top = "#{top}px"

  ROOT.style.margin = "0px 0px 0px 0px"
  ROOT.style.backgroundColor = backgroundColor
  ROOT.style.overflow = "hidden"

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html) =>
      if (html?)
        display = ROOT.style.display
        ROOT.style.display = "none"
        ROOT.innerHTML = html

      if (typeof APPLICATION.viewDidLoad == 'function')
        APPLICATION.viewDidLoad()

      ROOT.style.display = display

      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

