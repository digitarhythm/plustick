window.onload = ->
  APPLICATION = new appsmain()
  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.body.innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

