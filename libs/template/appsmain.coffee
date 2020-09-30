#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain
  constructor:->
    @html = """
      <div style="
        display: table-cell;
        text-align: center;
        vertical-align: middle;
        #border: 1px red solid;
        width: ===WIDTH===px;
        height: ===HEIGHT===px;
        margin: 0 auto;
        font-size: 24pt;
        color: gray;
      ">
        framework sample page.<br>
        version: ===VERSION===<br>
      </div>
    """

  createHTML:->
    return new Promise (resolve, reject)=>
      bounds = sysutil.getBounds()
      width = bounds.size.width
      height = bounds.size.height

      ret = await sysutil.APICALL
        endpoint: "version"
        data: {}

      result = @html.replace(/===WIDTH===/, width)
      result = result.replace(/===HEIGHT===/, height)
      result = result.replace(/===VERSION===/, ret.version)

      resolve(result)

