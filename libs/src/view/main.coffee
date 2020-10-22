APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()
  #rootview = document.querySelector("#_rootview_")
  #baseview = document.querySelector("#_baseview_")

  # browser resolution
  bounds = plustick.getBounds()
  browser_width = bounds.size.width
  browser_height = bounds.size.height
  browser_aspect = browser_width / browser_height

  #echo "browser_width=%@, browser_height=%@, browser_aspect=%@", browser_width, browser_height, browser_aspect

  # contents resolution
  contents_width = APPLICATION.width || browser_width
  contents_height = APPLICATION.height || browser_height
  contents_aspect = contents_width / contents_height

  #echo "contents_width=%@, contents_height=%@, contents_aspect=%@", contents_width, contents_height, contents_aspect

  # rootview setting
  root_width = browser_width
  root_height = browser_width / contents_aspect
  root_left = 0
  root_top = parseInt((browser_height - root_height) / 2)
  #echo "root_width=%@, root_height=%@, left=%@, top=%@", root_width, root_height, root_left, root_top
  if (root_height > browser_height)
    root_width = browser_height * contents_aspect
    root_height = browser_height
    root_left = parseInt((browser_width - root_width) / 2)
    root_top = 0
    #echo "root_width=%@, root_height=%@, left=%@, top=%@", root_width, root_height, root_left, root_top

  rootview = document.createElement("div")
  #rootview.setAttribute("id", "_rootview_")

  rootview.style.width = "#{root_width}px"
  rootview.style.height = "#{root_height}px"
  rootview.style.left = "#{root_left}px"
  rootview.style.top = "#{root_top}px"

  rootview.style.margin = "0px 0px 0px 0px"
  rootview.style.position = "absolute"
  rootview.style.backgroundColor = "black"
  rootview.style.overflow = "hidden"
  #rootview.style.border = "1px orange dotted"

  document.body.append(rootview)

  # contentsview setting
  contentsview = document.createElement("div")
  contentsview.setAttribute("id", "contentsview")
  contentsview.setAttribute("width", "#{contents_width}px")
  contentsview.setAttribute("height", "#{contents_height}px")

  contentsview.style.width = "100%"
  contentsview.style.height = "100%"
  contentsview.style.left = "0px"
  contentsview.style.top = "0px"

  contentsview.style.margin = "0px 0px 0px 0px"
  contentsview.style.position = "absolute"
  contentsview.style.backgroundColor = "black"
  contentsview.style.overflow = "hidden"
  #contentsview.style.border = "1px yellow dotted"

  rootview.append(contentsview)

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#contentsview').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

