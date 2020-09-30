#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain
  constructor:->

  createHtml:->
    return new Promise (resolve, reject)=>
      bounds = sysutil.getBounds()
      width = bounds.size.width
      height = bounds.size.height

      ret = await sysutil.APICALL
        endpoint: "version"
        data: {}
      @version = ret.version

      html = """
        <div style="
          display: table-cell;
          text-align: center;
          vertical-align: middle;
          #border: 1px red solid;
          width: #{width}px;
          height: #{height}px;
          margin: 0 auto;
          font-size: 24pt;
          color: gray;
        " id="contents">
        </div>
      """

      resolve(html)

  viewDidAppear:->
    elm = document.getElementById("contents")
    elm.innerHTML = """
      framework sample page.<br>
      version: #{@version}<br>
    """
