APPLICATION = undefined
window.onload = ->
  APPLICATION = new appsmain()
  if (typeof APPLICATION.createHtml == 'function')
    APPLICATION.createHtml().then (html)=>
      if (html?)
        document.querySelector('#_rootview_').innerHTML = html
      if (typeof APPLICATION.viewDidAppear == 'function')
        APPLICATION.viewDidAppear()

