#=============================================================================
# This class is the first class generated when the application is launched.
#=============================================================================
class appsmain
  constructor:->

  createHtml:->
    return new Promise (resolve, reject)=>
      bounds = plustick.getBounds()
      width = bounds.size.width
      height = bounds.size.height

      html = """
        <style type="text/css">
          button {
            color: rgba(255, 255, 255, 1.0);
						box-shadow: inset 0 10px 25px 0 rgba(0, 0, 0, .5);
						background-color: rgba(0, 127, 255, 0.8);
						border-radius: 8px;
						width: 120px;
          }
					button:hover {
						filter: drop-shadow(0 4px 4px rgba(0, 0, 0, .9));
					}
        </style>
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
    ret = await plustick.APICALL
      endpoint: "version"
      data: {}
    version = ret.version

    elm = document.getElementById("contents")
    elm.innerHTML = """
      framework sample page.<br>
      version: #{version}<br>
      <button id="button1">ボタン</button>
    """
    button = document.getElementById("button1")
    button.addEventListener "click", =>
      @click()

  click:->
    alert("クリック")
