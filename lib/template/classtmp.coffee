#=====================================
# template class file
#=====================================
class [[[:classname:]]] extends coreobject
  constructor: ->
    super()

  createHtml: ->
    super()
    return new Promise (resolve, reject) =>
      html = """
        <div id="#{@uniqueID}" class="[[[:classname:]]]">
        </div>
      """
      resolve(html)

  viewDidLoad: ->
    super()

  viewDidAppear: ->
    super()


