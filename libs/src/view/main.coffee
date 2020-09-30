$ ->
  APPLICATION = new appsmain()
  if (typeof APPLICATION.createHTML == "function")
    APPLICATION.createHTML().then (html)=>
      if (html?)
        document.body.innerHTML = html

