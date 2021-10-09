#=====================================
# template class file
#=====================================
class [[[:classname:]]] extends viewController
  constructor:(param) ->
    super(param)

  createHtml: ->
    # Value 'html' is page rendering HTML tag text.
    html = await super()

    html = """
    """

    return(html)

  viewDidLoad: ->
    super()

  viewDidAppear: ->
    super()

