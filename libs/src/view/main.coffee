$ ->
  APPLICATION = new appsmain()

  APPLICATION.createHtml().then (html)=>
    if (html?)
      document.body.innerHTML = html
    if (typeof APPLICATION.viewDidAppear == 'function')
      APPLICATION.viewDidAppear()

