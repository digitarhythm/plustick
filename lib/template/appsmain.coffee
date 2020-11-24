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
    getElement("contents").innerHTML = """
      <div id="version" onclick="
        plustick.procedure('#{@uniqueID}', 'version');
      ">
        Version?
      </div>
    """

    GLOBAL.PROC[@uniqueID].version = =>
      @click()

  #===========================================================================
  # It is executed after the HTML is displayed.
  #===========================================================================
  viewDidAppear:->

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
    ret = await plustick.APICALL
      endpoint: 'version'

    getElement("version").innerHTML = """
      Version: #{ret.version}
    """

