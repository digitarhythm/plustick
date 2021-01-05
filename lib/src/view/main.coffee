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
  #===========================================================================
  # resize event
  #===========================================================================
  window.addEventListener 'resize', ->
    contents_size = fitContentsSize(APPLICATION)
    ROOT.style.width = "#{contents_size.width}px"
    ROOT.style.height = "#{contents_size.height}px"
    ROOT.style.left = "#{contents_size.left}px"
    ROOT.style.top = "#{contents_size.top}px"

  #===========================================================================
  # fit contents size to browser
  #===========================================================================
  fitContentsSize = (apps)->
    # get browser size
    bounds = plustick.getBounds()
    browser_width = bounds.size.width
    browser_height = bounds.size.height
    browser_aspect = browser_width / browser_height

    if (apps.width? || apps.height?)
      contents_width = apps.width || parseInt(Math.round(apps.height * browser_aspect))
      contents_height = apps.height || parseInt(Math.round(apps.width / browser_aspect))
      apps.width = contents_width
      apps.height = contents_height

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
      apps.width = browser_width
      apps.height = browser_height
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
    APPLICATION.createHtml().then (html) =>
      if (html?)
        display = ROOT.style.display
        ROOT.style.display = "none"
        ROOT.innerHTML = html

      if (typeof APPLICATION.viewDidLoad == 'function')
        await APPLICATION.viewDidLoad()

      ROOT.style.display = display

      if (typeof APPLICATION.viewDidAppear == 'function')
        await APPLICATION.viewDidAppear()

