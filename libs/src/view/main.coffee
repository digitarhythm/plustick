APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()

  adjust = APPLICATION.adjust || false
  backgroundColor = APPLICATION.backgroundColor || "rgba(0, 0, 0, 1.0)"

  rootview = document.createElement("div")
  rootview.setAttribute("id", "__rootview__")
  document.body.append(rootview)

  bounds = plustick.getBounds()
  browser_width = bounds.size.width
  browser_height = bounds.size.height

  if (adjust)
    # contents resolution
    contents_width = APPLICATION.width || browser_width
    contents_height = APPLICATION.height || browser_height
    APPLICATION.width = contents_width
    APPLICATION.height = contents_height

    # browser resolution
    bounds = plustick.getBounds()
    browser_width = bounds.size.width
    browser_height = bounds.size.height

    scale_x = browser_width / contents_width
    scale_y = browser_height / contents_height
    scale_mode = 1

    height_tmp = contents_height * scale_x

    if (height_tmp > browser_height)
      scale_mode = 2

    if (scale_mode == 1)
      real_height = contents_height * scale_x
      left = 0
      top = parseInt((browser_height - real_height) / 2)
      scale = scale_x
    else
      real_width = contents_width * scale_y
      left = parseInt((browser_width - real_width) / 2)
      top = 0
      scale = scale_y

    rootview.style.transformOrigin = "0px 0px 0px"
    rootview.style.transform = "scale(#{scale}, #{scale})"

  else
    # contents resolution
    contents_width = browser_width
    contents_height = browser_height
    APPLICATION.width = browser_width
    APPLICATION.height = browser_height
    left = 0
    top = 0

  rootview.style.position = "absolute"
  rootview.style.width = "#{contents_width}px"
  rootview.style.height = "#{contents_height}px"
  rootview.style.left = "#{left}px"
  rootview.style.top = "#{top}px"

  rootview.style.margin = "0px 0px 0px 0px"
  rootview.style.backgroundColor = backgroundColor
  rootview.style.overflow = "hidden"

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#__rootview__').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

