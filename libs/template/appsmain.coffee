#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain
  constructor:->
    @width = undefined
    @height = undefined
    @contextmenu = true

  createHtml:->
    return new Promise (resolve, reject)=>

      html = """
        <div style="
          display: table-cell;
          text-align: center;
          vertical-align: middle;
          width: #{@width}px;
          height: #{@height}px;
          margin: 0 auto;
          font-size: 24pt;
          color: rgba(0, 127, 255, 0.8);
        " id="contents">
        </div>
      """

      resolve(html)

  viewDidAppear:->
    ret = await plustick.APICALL
      endpoint: "version"
      data: {}
    version = ret.version

    elm = getElement("contents")
    elm.innerHTML = """
      framework sample page.<br>
      version: #{version}<br>
      <input type="button" id="button1" value="ボタン">
    """
    button = getElement("button1")
    button.addEventListener "click", =>
      @click()

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

