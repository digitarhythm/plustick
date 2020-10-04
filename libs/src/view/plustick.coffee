ORIGIN = window.location.href.replace(/\/$/, "")
requestAnimationFrame = window.requestAnimationFrame ||
                        window.mozRequestAnimationFrame ||
                        window.webkitRequestAnimationFrame ||
                        window.msRequestAnimationFrame
window.requestAnimationFrame = requestAnimationFrame

#===========================================================================
# nop
#===========================================================================
nop = ->

#===========================================================================
# debug write
#===========================================================================
echo = (a, b...) ->
  #console.log(a)
  for data in b
    if (typeof(data) == 'object')
      data = JSON.stringify(data)
    a = a.replace('%@', data)
  console.log(a)
  return a

#===========================================================================
# system utility class
#===========================================================================
class plustick
  # format strings
  @sprintf = (a, b...)->
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
  @getBounds:->
    width = window.innerWidth - 1
    height = window.innerHeight - 1
    frame = []
    frame.size = []
    frame.size.width = width
    frame.size.height = height
    return frame

  #===========================================================================
  #===========================================================================
  @random:(max) ->
    return Math.floor(Math.random() * (max + 1))

  #===========================================================================
  #===========================================================================
  @getBrowser:->
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
  @animate:(duration, id, cssparam, finished=undefined)->
    anim_tmp = 10.0

    #=========================================================================
    anim_proc = (id, param_diff)->
      elm = document.getElementById(id)
      flag = true
      for key of param_diff
        cssparam = param_diff[key]
        diff = parseFloat(cssparam['diff'])
        val = parseFloat(cssparam['val'])

        cssval = parseFloat(elm.style[key])
        cssval += diff

        if (['top', 'left', 'width', 'height'].indexOf(key) < 0)
          cssstr = cssval
        else
          cssstr = (parseInt(cssval)).toString()+"px"
        elm.style[key] = cssstr

        if ((cssval == val) || (diff > 0 && cssval > val) || (diff < 0 && cssval < val))
          if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing'].indexOf(key) < 0)
            cssstr = val
          else
            cssstr = (parseInt(val)).toString()+"px"
          elm.style[key] = cssstr
          flag = false

      if (flag)
        setTimeout ->
          flag = anim_proc(id, param_diff)
        , anim_tmp
      else
        if (finished?)
          finished()
    #=========================================================================

    elm = document.getElementById(id)
    if (!elm? || !cssparam?)
      return

    param_diff = {}
    for key of cssparam
      cssstr = elm.style[key]
      cssval = parseFloat(elm.style[key].replace(/[^0-9\.]/, ""))
      if (cssval == "" || !cssval?)
        continue

      val = parseFloat(cssparam[key])
      diff = (val - cssval) / (duration / anim_tmp)
      param_diff[key] =
        diff: (val - cssval) / (duration / anim_tmp)
        val: val

    anim_proc(id, param_diff)

  #===========================================================================
  #===========================================================================
  @APICALL:(param=undefined)->
    if (!param.endpoint?)
      return -1

    method = param.method || "POST"
    endpoint = param.endpoint
    data = param.data || {}
    headers = param.headers || {}
    headers['content-type'] = "application/json"

    uri = "#{ORIGIN}/#{pkgname}/api/#{endpoint}"

    ret = await axios
      method: method
      url: uri
      headers: headers
      data: data

    if (ret.data.error? && ret.data.error < 0)
      return -2
    else
      return ret.data

