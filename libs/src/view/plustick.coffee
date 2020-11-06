#===========================================================================
# nop
#===========================================================================
nop =->

#===========================================================================
# debug write
#===========================================================================
echo = (a, b...)->
  #console.log(a)
  for data in b
    if (typeof(data) == 'object')
      data = JSON.stringify(data)
    a = a.replace('%@', data)
  console.log(a)
  return a

getElement = (elmname)->
  return document.querySelector("#"+elmname)

#===========================================================================
# system utility class
#===========================================================================
class plustick_core
  constructor:->
    @eventlistener = {}

  # format strings
  sprintf:(a, b...)->
    for data in b
      match = a.match(/%0\d*@/)
      if (match?)
        repstr = match[0]
        num = parseInt(repstr.match(/\d+/))
        zero =""
        zero += "0" while (zero.length < num)
        data2 = (zero+data).substr(-num)
        a = a.replace(repstr, data2)
      else
        a = a.replace('%@', data)
    return a

  #===========================================================================
  # get browser size(include scrolling bar)
  #===========================================================================
  getBounds:->
    width = window.innerWidth
    height = window.innerHeight
    frame = []
    frame.size = []
    frame.size.width = width
    frame.size.height = height
    return frame

  #===========================================================================
  #===========================================================================
  random:(max) ->
    return Math.floor(Math.random() * (max + 1))

  #===========================================================================
  #===========================================================================
  getBrowser:->
    ua = navigator.userAgent
    if (ua.match(".*iPhone.*"))
      kind = 'iOS'
    else if (ua.match(".*Android"))
      kind = 'Android'
    else if (ua.match(".*Windows.*"))
      kind = 'Windows'
    else if (ua.match(".*BlackBerry.*"))
      kind = 'BlackBerry'
    else if (ua.match(".*Symbian.*"))
      kind = 'Symbian'
    else if (ua.match(".*Macintosh.*"))
      kind = 'Mac'
    else if (ua.match(".*Linux.*"))
      kind = 'Linux'
    else
      kind = 'Unknown'

    if (ua.match(".*Safari.*") && !ua.match(".*Android.*") && !ua.match(".*Chrome.*"))
      browser = 'Safari'
    else if (ua.match(".*Gecko.*Firefox.*"))
      browser = "Firefox"
    else if (ua.match(".*Opera*"))
      browser = "Opera"
    else if (ua.match(".*MSIE*"))
      browser = "MSIE"
    else if (ua.match(".*Gecko.*Chrome.*"))
      browser = "Chrome"
    else
      browser = 'Unknown'

    return {'kind':kind, 'browser':browser}

  #===========================================================================
  #===========================================================================
  animate:(duration, target_id, toparam, finished=undefined)->
    anim_tmp = 10.0

    #=========================================================================
    anim_proc = (element, cssparam)=>
      flag = true
      for key of cssparam
        toparam = cssparam[key]
        diff = parseFloat(toparam['diff'])
        val = parseFloat(toparam['val'])

        cssval = parseFloat(element.style.opacity)
        cssval += diff

        if (['top', 'left', 'width', 'height'].indexOf(key) < 0)
          cssstr = cssval
        else
          cssstr = (parseInt(cssval)).toString()+"px"
        element.style[key] = cssstr

        if ((cssval == val) || (diff > 0 && cssval > val) || (diff < 0 && cssval < val))
          if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing', ].indexOf(key) < 0)
            cssstr = val
          else
            cssstr = (parseInt(val)).toString()+"px"

          element.style[key] = cssstr
          flag = false

      if (flag)
        setTimeout =>
          anim_proc(element, cssparam)
        , anim_tmp
      else
        if (finished?)
          setTimeout =>
            finished()
          , 100
    #=========================================================================

    element = document.getElementById(target_id)
    if (!element? || !toparam?)
      return

    cssparam = {}
    for key of toparam
      fromcss_tmp = element.style[key] || undefined
      if (!fromcss_tmp?)
        fromcss_str = 1.0
        element.style[key] = fromcss_str
      else
        fromcss_str = fromcss_tmp
      fromcss = parseFloat(fromcss_str.toString().replace(/[^0-9\.\-]/, ""))
      if (fromcss == "" || !fromcss?)
        continue

      val = parseFloat(toparam[key])
      diff = (val - fromcss) / (duration / anim_tmp)
      cssparam[key] =
        diff: (val - fromcss) / (duration / anim_tmp)
        val: val

    anim_proc(element, cssparam)

  #===========================================================================
  #===========================================================================
  addListener:(id, type, listener, capture=false)->
    key="#{id}_#{type}"
    if(@eventlistener[key]?)
      e = @eventlistener["#{id}_#{type}"]
      e.target.removeEventListener(type, e.listener, e.capture)

    target = document.querySelector("##{id}")
    target.addEventListener(type, listener, capture)
    @eventlistener["#{id}_#{type}"] =
        target: target
        listener: listener
        capture: capture

  #===========================================================================
  #===========================================================================
  removeListener:(id, type)->
    if("#{id}_#{type}" in @eventlistener)
      e = @eventlistener["#{id}_#{type}"]
      e.target.removeEventListener(type, e.listener, e.capture)

  #===========================================================================
  #===========================================================================
  procedure:(key)->
    proc = GLOBAL.PROC
    if (!proc[key]?)
      return

    proc[key]()
    proc[key] = undefined

  #===========================================================================
  #===========================================================================
  checkEan13Code:(code)->
    codestr = code.toString()
    if (codestr.length != 13)
      return undefined

    odd = 0
    oddstr = ""
    even = 0
    evenstr = ""
    for i in [13..2] by -1
      pos = 13 - i
      s = codestr[pos..pos]
      if (i % 2 == 0)
        even += parseInt(s)
        evenstr += s
      else
        odd += parseInt(s)
        oddstr += s

    checkdigit = parseInt(codestr.slice(-1))

    total = ((even * 3) + odd).toString()
    totalstr = total.slice(-1)

    checkdigit2 = (10 - parseInt(totalstr)) % 10

    if (checkdigit == checkdigit2)
      err = 0
    else
      err = -1

    return
      code: code
      err: err

  #===========================================================================
  #===========================================================================
  APICALL:(param=undefined)->
    if (!param.endpoint? && !param.uri?)
      return -1

    method = param.method || "POST"
    endpoint = param.endpoint || undefined
    uri = param.uri || undefined
    data = param.data || {}
    headers = param.headers || {}
    headers['content-type'] = "application/json"

    if (uri?)
      apiuri = uri
    else
      apiuri = "#{ORIGIN}/api/#{endpoint}"

    ret = await axios
      method: method
      url: apiuri
      headers: headers
      data: data

    if (ret.data.error? && ret.data.error < 0)
      return -2
    else
      return ret.data


plustick = new plustick_core()

