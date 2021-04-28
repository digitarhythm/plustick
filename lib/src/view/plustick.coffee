#=============================================================================
# nop
#=============================================================================
nop = ->

#=============================================================================
# text formatter
#=============================================================================
__strFormatter__ = (a, b...) ->
  for data in b
    if (Object.prototype.toString.call(data) == "[object Object]")
      data = JSON.stringify(data)
    repl = a.match(/(\%.*?@)/)
    if (repl?)
      repstr = repl[1]
      repl2 = repstr.match(/%0(\d+)@/)
      if (repl2?)
        num = parseInt(repl2[1])
        zero = ""
        zero += "0" while (zero.length < num)
        data2 = (zero+data).substr(-num)
        a = a.replace(repstr, data2)
      else
        a = a.replace('%@', data)
  return a

#=============================================================================
# debug write
#=============================================================================
echo = (a, b...) ->
  if (node_env == "develop")
    console.log(__strFormatter__(a, b...))

#=============================================================================
# DOM Operation
#=============================================================================
getElement = (id) ->
  return document.getElementById(id)

setHtml = (id, html) ->
  elm = document.getElementById(id)
  if (elm?)
    elm.innerHTML = html
  else
    console.error("id: ["+id+"] is undefined.")

#=============================================================================
# system utility class
#=============================================================================
class plustick_core
  constructor: ->
    @eventlistener = {}

  #===========================================================================
  # format strings
  #===========================================================================
  sprintf:(a, b...) ->
    return __strFormatter__(a, b...)

  #===========================================================================
  # get browser size(include scrolling bar)
  #===========================================================================
  getBounds: ->
    width = window.innerWidth
    height = window.innerHeight
    frame =
      size:
        width: width
        height: height
        aspect: width / height
    return frame

  #===========================================================================
  # get random value
  #===========================================================================
  random:(max) ->
    return Math.floor(Math.random() * (max + 1))

  #===========================================================================
  # get browser name
  #===========================================================================
  getBrowser: ->
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
  # CSS Animation
  #===========================================================================
  animate:(duration, target_id, toparam, finished=undefined) ->
    anim_tmp = 10.0

    #=========================================================================
    anim_proc = (element, cssparam) =>
      flag = true
      for key of cssparam
        toparam = cssparam[key]
        diff = parseFloat(toparam['diff'])
        val = parseFloat(toparam['val'])

        cssval = parseFloat(element.style.opacity)
        cssval += diff

        if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing'].indexOf(key) >= 0)
          cssstr = (parseInt(cssval)).toString()+"px"
        else if (['font-size'].indexOf(key) >= 0)
          cssstr = (parseInt(cssval)).toString()+"pt"
        else
          cssstr = cssval
        element.style[key] = cssstr

        if ((cssval == val) || (diff > 0 && cssval > val) || (diff < 0 && cssval < val))
          if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing', ].indexOf(key) >= 0)
            cssstr = (parseInt(val)).toString()+"px"
          else if (['font-size'].indexOf(key) >= 0)
            cssstr = (parseInt(val)).toString()+"pt"
          else
            cssstr = val

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
  # add event listener
  #===========================================================================
  addListener:(param) ->
    id = param.id || undefined
    type = param.type || undefined
    listener = param.listener || undefined
    passive = param.passive || false
    capture = param.capture || false

    if (!id? || !type?)
      return

    typelist = type.split(/ /)
    for t in typelist
      @removeListener
        id: id
        type: t

    method1 = (event) ->
      event.preventDefault()
      type = event.type
      posevent = [
        "click"
        "dblclick"
        "tap"
        "dbltap"
        "mousedown"
        "mousemove"
        "mouseup"
        "touchstart"
        "touchmove"
      ]
      if (posevent.indexOf(type) >= 0)
        if (type.match(/touch.*/) || type == "tap")
          clientX = event.touches[0].clientX
          clientY = event.touches[0].clientY
          passive = true
        else
          clientX = event.clientX
          clientY = event.clientY

        rect = event.currentTarget.getBoundingClientRect()
        x = clientX - rect.left
        y = clientY - rect.top
        width = rect.width
        height = rect.height

        size = {
          width: Math.floor(width)
          height: Math.floor(height)
        }

        pos = {
          offsetX: parseInt(x)
          offsetY: parseInt(y)
          clientX: parseInt(clientX)
          clientY: parseInt(clientY)
        }

      else
        size = undefined
        pos = undefined

      if (size? && pos?)
        frame =
          size: size
          pos: pos

        listener(event, frame)
      else
        listener(event)

    method2 = (event) ->
      event.preventDefault()
      listener(event)

    if (id == "window")
      target = window
      method = method2
    else
      target = getElement(id)
      method = method1

    for t in typelist
      target.addEventListener t, method, capture, {passive: true}
      key="#{id}_#{t}"
      @eventlistener[key] =
        target: target
        type: t
        listener: method
        capture: capture

  #===========================================================================
  # remove event listener
  #===========================================================================
  removeListener:(param) ->
    id = param.id
    type = param.type
    typelist = type.split(/ /)

    for t in typelist
      key="#{id}_#{t}"
      if (@eventlistener[key]?)
        e = @eventlistener[key]
        e.target.removeEventListener(t, e.listener, e.capture)
        @eventlistener[key] = undefined

  #===========================================================================
  # execute procedure for key
  #===========================================================================
  procedure:(id, key=undefined, param=undefined, argument=undefined) ->
    if (argument?)
      event = argument[0]

    obj = GLOBAL.PROC[id]
    if (!obj?)
      return

    try
      obj[key](param, event)

  #===========================================================================
  # check EAN13 code formatte
  #===========================================================================
  checkEan13Code:(code) ->
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
  # Call Ajax
  #===========================================================================
  APICALL:(param=undefined) ->
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
      apiuri = "#{SITEURL}/api/#{endpoint}"

    ret = await axios
      method: method
      url: apiuri
      headers: headers
      data: data

    if (ret.data.error? && ret.data.error < 0)
      return -2
    else
      return ret.data

  #=========================================================================
  # copy object auto classification
  #=========================================================================
  copyObj:(a) ->
    cpObj = (a) ->
      return Object.assign({}, a)
    cpArr = (a) ->
      return a.concat()

    type = Object.prototype.toString.call(a)

    array_list = [
      "[object Array]"
    ]
    object_list = [
      "[object Object]"
      "[object Function]"
    ]

    if (array_list.indexOf(type) >= 0)
      return cpArr(a)
    else if (object_list.indexOf(type) >= 0)
      return cpObj(a)

  #=========================================================================
  #=========================================================================
  addOrientationProc:(proc) ->
    if (APPLICATION.orientation && DEVICEORIENTATION)
      @addListener
        id: "window"
        type: "deviceorientationabsolute"
        capture: true
        listener: (e) =>
          if (proc?)
            proc
              absolute: e.absolute
              alpha: e.alpha
              beta: e.beta
              gamma: e.gamma

  removeOrientationProc: ->
    @removeListener
      id: "window"
      type: "deviceorientationabsolute"

  addMotionProc:(proc) ->
    if (APPLICATION.motion)
      @addListener
        id: "window"
        type: "devicemotion"
        capture: true
        listener: (e) =>
          if (proc?)
            proc
              x: e.accelerationIncludingGravity.x
              y: e.accelerationIncludingGravity.y
              z: e.accelerationIncludingGravity.z

  removeMotionProc: ->
    @removeListener
      id: "window"
      type: "devicemotion"

plustick = new plustick_core()

