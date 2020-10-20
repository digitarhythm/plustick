APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()

  bgcolor = APPLICATION.backgroundColor
  overflow = APPLICATION.overflow

  document.body.style.backgroundColor = bgcolor

  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#_rootview_').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

