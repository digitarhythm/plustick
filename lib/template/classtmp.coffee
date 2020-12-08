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
        <div id="#{@uniqueID}" style="
          overflow: hidden;
          background-color: rgba(0, 0, 0, 1.0);
          color: rgba(255, 255, 255, 1.0);
        ">
        </div>
      """
      resolve(html)

  viewDidLoad: ->
    super()

  viewDidAppear: ->
    super()


