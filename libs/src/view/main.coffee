APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()

  bgcolor = APPLICATION.backgroundColor
  overflow = APPLICATION.overflow
  rootwidth = APPLICATION.rootwidth
  rootheight = APPLICATION.rootheight

  document.body.style.backgroundColor = bgcolor
  document.body.style.width = "#{rootwidth}px"
  document.body.style.height = "#{rootheight}px"

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#_rootview_').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

