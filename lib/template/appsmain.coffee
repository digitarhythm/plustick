#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain extends viewController
  #===========================================================================
  # define application environ value
  #===========================================================================
  constructor: ->
    super()
    @contextmenu = true
    @orientation = false
    @motion = false

    @idxstorage = new indexStorage()

  #===========================================================================
  # define template HTML
  #===========================================================================
  createHtml: ->
    html = await super()
    html = """
      <div id="#{@uniqueID}" class="appsmain">
        Hello World!
      </div>
    """

    return(html)

  #===========================================================================
  # After the HTML is loaded, but before it is displayed, it is executed.
  #===========================================================================
  viewDidLoad: ->
    super()
    plustick.addListener
      id: @uniqueID
      type: "mousedown touchstart"
      listener: (event, frame) =>
        @click()

  #===========================================================================
  # It is executed after the HTML is displayed.
  #===========================================================================
  viewDidAppear: ->
    super()

  #===========================================================================
  #===========================================================================
  #===========================================================================
  #
  # Below this are user-defined methods.
  #
  #===========================================================================
  #===========================================================================
  #===========================================================================

  click: ->
    ret = await plustick.APICALL
      endpoint: 'version'

    getElement("contents").innerHTML = """
      Apps Version: #{ret.version}
    """

