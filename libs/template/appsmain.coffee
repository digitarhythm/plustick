#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain extends coreobject
  #===========================================================================
  # define application environ value
  #===========================================================================
  constructor:->
    super()
    @width = undefined
    @height = undefined
    @contextmenu = true

  #===========================================================================
  # define template HTML
  #===========================================================================
  createHtml:->
    return new Promise (resolve, reject)=>
      html = """
        <div id="contents"></div>
      """

      resolve(html)

  #===========================================================================
  # After the HTML is loaded, but before it is displayed, it is executed.
  #===========================================================================
  viewDidLoad:->

  #===========================================================================
  # It is executed after the HTML is displayed.
  #===========================================================================
  viewDidAppear:->
    getElement("contents").style.width = "#{@width}px"
    getElement("contents").style.height = "#{@height}px"

    ret = await plustick.APICALL
      endpoint: "version"
      data: {}
    version = ret.version

    getElement("contents").innerHTML = """
      <span id="version" onclick="plustick.procedure('#{@uniqueID}', 'version', '#{version}')">
        disp version
      </span>
    """

    GLOBAL.PROC[@uniqueID] = (param)=>
      @click(param.version)

  #===========================================================================
  #===========================================================================
  #===========================================================================
  #
  # Below this are user-defined methods.
  #
  #===========================================================================
  #===========================================================================
  #===========================================================================

  click:->
    plustick.animate 300, "contents",
      opacity: 0.3
    , =>
      ret = confirm("クリック")
      if (ret)
        getElement("button1").setAttribute("value", "OK")
      else
        getElement("button1").setAttribute("value", "キャンセル")
      plustick.animate 300, "contents",
        opacity: 1.0

