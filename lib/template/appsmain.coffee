#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain extends coreobject
  #===========================================================================
  # define application environ value
  #===========================================================================
  constructor: ->
    super()
    @width = undefined
    @height = undefined
    @contextmenu = true

  #===========================================================================
  # define template HTML
  #===========================================================================
  createHtml: ->
    html = await super()
    return new Promise (resolve, reject) =>
      html = """
        <div id="#{@uniqueID}">
          Version?
        </div>
      """

      resolve(html)

  #===========================================================================
  # After the HTML is loaded, but before it is displayed, it is executed.
  #===========================================================================
  viewDidLoad: ->
    super()
    plustick.addListener @uniqueID, "click tap", (self, pos) =>
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

    getElement(@uniqueID).innerHTML = """
      Version: #{ret.version}
    """

