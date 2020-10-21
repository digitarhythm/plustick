APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()

  bounds = plustick.getBounds()
  rootwidth = APPLICATION.rootwidth || bounds.size.width
  rootheight = APPLICATION.rootheight || bounds.size.height
  APPLICATION.rootwidth = rootwidth
  APPLICATION.rootheight = rootheight

  left = parseInt((bounds.size.width - rootwidth) / 2)
  top = parseInt((bounds.size.height - rootheight) / 2)

  rootview = document.querySelector("#_rootview_")

  rootview.setAttribute("width", rootwidth)
  rootview.setAttribute("height", rootheight)

  rootview.style.width = "#{rootwidth}px"
  rootview.style.height = "#{rootheight}px"
  rootview.style.left = "#{left}px"
  rootview.style.top = "#{top}px"

  bgcolor = APPLICATION.backgroundColor || "black"
  rootview.style.backgroundColor = bgcolor

  overflow = APPLICATION.overflow || "hidden"
  rootview.style.overflow = overflow

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#_rootview_').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

