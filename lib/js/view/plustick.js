//=============================================================================
// nop
//=============================================================================
var __strFormatter__, echo, getElement, nop, plustick, plustick_core, setHtml;

nop = function() {};

//=============================================================================
// text formatter
//=============================================================================
__strFormatter__ = function(a, ...b) {
  var data, data2, j, len, num, repl, repl2, repstr, zero;
  for (j = 0, len = b.length; j < len; j++) {
    data = b[j];
    if (Object.prototype.toString.call(data) === "[object Object]") {
      data = JSON.stringify(data);
    }
    repl = a.match(/(\%.*?@)/);
    if ((repl != null)) {
      repstr = repl[1];
      repl2 = repstr.match(/%0(\d+)@/);
      if ((repl2 != null)) {
        num = parseInt(repl2[1]);
        zero = "";
        while (zero.length < num) {
          zero += "0";
        }
        data2 = (zero + data).substr(-num);
        a = a.replace(repstr, data2);
      } else {
        a = a.replace('%@', data);
      }
    }
  }
  return a;
};

//=============================================================================
// debug write
//=============================================================================
echo = function(a, ...b) {
  if (NODE_ENV === "develop") {
    return console.log(__strFormatter__(a, ...b));
  }
};

//=============================================================================
// DOM Operation
//=============================================================================
getElement = function(id) {
  return document.getElementById(id);
};

setHtml = function(id, html) {
  var elm;
  elm = document.getElementById(id);
  if ((elm != null)) {
    return elm.innerHTML = html;
  } else {
    return console.error("id: [" + id + "] is undefined.");
  }
};

//=============================================================================
// system utility class
//=============================================================================
plustick_core = class plustick_core {
  constructor() {
    this.eventlistener = {};
  }

  //===========================================================================
  // format strings
  //===========================================================================
  sprintf(a, ...b) {
    return __strFormatter__(a, ...b);
  }

  //===========================================================================
  // get browser size(include scrolling bar)
  //===========================================================================
  getBounds() {
    var frame, height, width;
    width = window.innerWidth;
    height = window.innerHeight;
    frame = {
      size: {
        width: width,
        height: height,
        aspect: width / height
      }
    };
    return frame;
  }

  //===========================================================================
  // get random value
  //===========================================================================
  random(max) {
    return Math.floor(Math.random() * (max + 1));
  }

  //===========================================================================
  // get browser name
  //===========================================================================
  getBrowser() {
    var browser, kind, ua;
    ua = navigator.userAgent;
    if (ua.match(".*iPhone.*")) {
      kind = 'iOS';
    } else if (ua.match(".*Android")) {
      kind = 'Android';
    } else if (ua.match(".*Windows.*")) {
      kind = 'Windows';
    } else if (ua.match(".*BlackBerry.*")) {
      kind = 'BlackBerry';
    } else if (ua.match(".*Symbian.*")) {
      kind = 'Symbian';
    } else if (ua.match(".*Macintosh.*")) {
      kind = 'Mac';
    } else if (ua.match(".*Linux.*")) {
      kind = 'Linux';
    } else {
      kind = 'Unknown';
    }
    if (ua.match(".*Safari.*") && !ua.match(".*Android.*") && !ua.match(".*Chrome.*")) {
      browser = 'Safari';
    } else if (ua.match(".*Gecko.*Firefox.*")) {
      browser = "Firefox";
    } else if (ua.match(".*Opera*")) {
      browser = "Opera";
    } else if (ua.match(".*MSIE*")) {
      browser = "MSIE";
    } else if (ua.match(".*Gecko.*Chrome.*")) {
      browser = "Chrome";
    } else {
      browser = 'Unknown';
    }
    return {
      'kind': kind,
      'browser': browser
    };
  }

  //===========================================================================
  // CSS Animation
  //===========================================================================
  animate(param) {
    var anim_proc, anim_tmp, cssparam, diff, duration, element, finished, fromcss, fromcss_str, fromcss_tmp, id, key, toparam, val;
    duration = param.duration || 0.3;
    id = param.id || this.uniqueID;
    toparam = param.param || {};
    finished = param.finished || void 0;
    anim_tmp = 10.0;
    //=========================================================================
    anim_proc = (element, cssparam) => {
      var cssstr, cssval, diff, flag, key, val;
      flag = true;
      for (key in cssparam) {
        toparam = cssparam[key];
        diff = parseFloat(toparam['diff']);
        val = parseFloat(toparam['val']);
        cssval = parseFloat(element.style.opacity);
        cssval += diff;
        if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing'].indexOf(key) >= 0) {
          cssstr = (parseInt(cssval)).toString() + "px";
        } else if (['font-size'].indexOf(key) >= 0) {
          cssstr = (parseInt(cssval)).toString() + "pt";
        } else {
          cssstr = cssval;
        }
        element.style[key] = cssstr;
        if ((cssval === val) || (diff > 0 && cssval > val) || (diff < 0 && cssval < val)) {
          if (['top', 'left', 'width', 'height', 'line-height', 'padding', 'spacing'].indexOf(key) >= 0) {
            cssstr = (parseInt(val)).toString() + "px";
          } else if (['font-size'].indexOf(key) >= 0) {
            cssstr = (parseInt(val)).toString() + "pt";
          } else {
            cssstr = val;
          }
          element.style[key] = cssstr;
          flag = false;
        }
      }
      if (flag) {
        return setTimeout(() => {
          return anim_proc(element, cssparam);
        }, anim_tmp);
      } else {
        if ((finished != null)) {
          return setTimeout(() => {
            return finished();
          }, 100);
        }
      }
    };
    //=========================================================================
    element = document.getElementById(id);
    if ((element == null) || (toparam == null)) {
      return;
    }
    cssparam = {};
    for (key in toparam) {
      fromcss_tmp = element.style[key] || void 0;
      if (fromcss_tmp == null) {
        fromcss_str = 1.0;
        element.style[key] = fromcss_str;
      } else {
        fromcss_str = fromcss_tmp;
      }
      fromcss = parseFloat(fromcss_str.toString().replace(/[^0-9\.\-]/, ""));
      if (fromcss === "" || (fromcss == null)) {
        continue;
      }
      val = parseFloat(toparam[key]);
      diff = (val - fromcss) / (duration / anim_tmp);
      cssparam[key] = {
        diff: (val - fromcss) / (duration / anim_tmp),
        val: val
      };
    }
    return anim_proc(element, cssparam);
  }

  //===========================================================================
  // add event listener
  //===========================================================================
  addListener(param) {
    var capture, id, j, k, key, len, len1, listener, method, method1, method2, propagation, results, t, target, type, typelist;
    id = param.id || void 0;
    type = param.type || void 0;
    listener = param.listener || void 0;
    capture = param.capture || false;
    propagation = param.propagation || false;
    if ((id == null) || (type == null)) {
      return;
    }
    typelist = type.split(/ /);
    for (j = 0, len = typelist.length; j < len; j++) {
      t = typelist[j];
      this.removeListener({
        id: id,
        type: t
      });
    }
    method1 = function(event) {
      var force, frame, k, kind, len1, p, passive, pos, posevent, rect, ref, size;
      rect = event.currentTarget.getBoundingClientRect();
      type = event.type;
      posevent = ["click", "dblclick", "tap", "dbltap", "mousedown", "mousemove", "mouseup", "touchstart", "touchmove"];
      if (posevent.indexOf(type) >= 0) {
        if (type.match(/touch.*/) || type === "tap") {
          pos = [];
          ref = event.touches;
          for (k = 0, len1 = ref.length; k < len1; k++) {
            p = ref[k];
            force = p.force || 1.0;
            if (p.radiusX === 0.50 && p.radiusY === 0.50) {
              kind = "stylus";
            } else {
              kind = "finger";
            }
            pos.push({
              clientX: parseInt(p.clientX / BROWSER_FRAME.scale),
              clientY: parseInt(p.clientY / BROWSER_FRAME.scale),
              offsetX: parseInt((p.clientX - rect.left) / BROWSER_FRAME.scale),
              offsetY: parseInt((p.clientY - rect.top) / BROWSER_FRAME.scale),
              kind: kind,
              force: p.force
            });
          }
          passive = true;
        } else {
          pos = [
            {
              clientX: parseInt(event.clientX),
              clientY: parseInt(event.clientY),
              offsetX: parseInt(event.clientX - rect.left),
              offsetY: parseInt(event.clientY - rect.top),
              kind: "mouse",
              force: 1.0
            }
          ];
        }
        size = {
          width: parseInt(rect.width),
          height: parseInt(rect.height)
        };
      } else {
        size = void 0;
        pos = void 0;
      }
      if ((size != null) && (pos != null)) {
        frame = {
          size: size,
          pos: pos
        };
        return listener(event, frame);
      } else {
        return listener(event);
      }
    };
    method2 = function(event) {
      return listener(event);
    };
    if (id === "window") {
      target = window;
      method = method2;
    } else {
      target = getElement(id);
      method = method1;
    }
    results = [];
    for (k = 0, len1 = typelist.length; k < len1; k++) {
      t = typelist[k];
      target.addEventListener(t, (event) => {
        if (!propagation) {
          event.stopPropagation();
        }
        return method(event);
      }, capture, {
        passive: true
      });
      key = `${id}_${t}`;
      results.push(this.eventlistener[key] = {
        target: target,
        type: t,
        listener: method,
        capture: capture
      });
    }
    return results;
  }

  //===========================================================================
  // remove event listener
  //===========================================================================
  removeListener(param) {
    var e, id, j, key, len, results, t, type, typelist;
    id = param.id;
    type = param.type;
    typelist = type.split(/ /);
    results = [];
    for (j = 0, len = typelist.length; j < len; j++) {
      t = typelist[j];
      key = `${id}_${t}`;
      if ((this.eventlistener[key] != null)) {
        e = this.eventlistener[key];
        e.target.removeEventListener(t, e.listener, e.capture);
        results.push(this.eventlistener[key] = void 0);
      } else {
        results.push(void 0);
      }
    }
    return results;
  }

  //===========================================================================
  // execute procedure for key
  //===========================================================================
  procedure(id, key = void 0, param = void 0, argument = void 0) {
    var event, obj;
    if ((argument != null)) {
      event = argument[0];
    }
    obj = GLOBAL.PROC[id];
    if (obj == null) {
      return;
    }
    try {
      return obj[key](param, event);
    } catch (error) {}
  }

  //===========================================================================
  // check EAN13 code formatte
  //===========================================================================
  checkEan13Code(code) {
    var checkdigit, checkdigit2, codestr, err, even, evenstr, i, j, odd, oddstr, pos, s, total, totalstr;
    codestr = code.toString();
    if (codestr.length !== 13) {
      return void 0;
    }
    odd = 0;
    oddstr = "";
    even = 0;
    evenstr = "";
    for (i = j = 13; j >= 2; i = j += -1) {
      pos = 13 - i;
      s = codestr.slice(pos, +pos + 1 || 9e9);
      if (i % 2 === 0) {
        even += parseInt(s);
        evenstr += s;
      } else {
        odd += parseInt(s);
        oddstr += s;
      }
    }
    checkdigit = parseInt(codestr.slice(-1));
    total = ((even * 3) + odd).toString();
    totalstr = total.slice(-1);
    checkdigit2 = (10 - parseInt(totalstr)) % 10;
    if (checkdigit === checkdigit2) {
      err = 0;
    } else {
      err = -1;
    }
    return {
      code: code,
      err: err
    };
  }

  //===========================================================================
  // Call Ajax
  //===========================================================================
  async APICALL(param = void 0) {
    var apiuri, data, endpoint, headers, method, ret, uri;
    if ((param.endpoint == null) && (param.uri == null)) {
      return -1;
    }
    method = param.method || "POST";
    endpoint = param.endpoint || void 0;
    uri = param.uri || void 0;
    data = param.data || {};
    headers = param.headers || {};
    headers['content-type'] = "application/json";
    if ((uri != null)) {
      apiuri = uri;
    } else {
      apiuri = `${SITEURL}/api/${endpoint}`;
    }
    ret = (await axios({
      method: method,
      url: apiuri,
      headers: headers,
      data: data
    }));
    if ((ret.data.error != null) && ret.data.error < 0) {
      return -2;
    } else {
      return ret.data;
    }
  }

  //=========================================================================
  // copy object auto classification
  //=========================================================================
  copyObj(a) {
    var array_list, cpArr, cpObj, object_list, type;
    cpObj = function(a) {
      return Object.assign({}, a);
    };
    cpArr = function(a) {
      return a.concat();
    };
    type = Object.prototype.toString.call(a);
    array_list = ["[object Array]"];
    object_list = ["[object Object]", "[object Function]"];
    if (array_list.indexOf(type) >= 0) {
      return cpArr(a);
    } else if (object_list.indexOf(type) >= 0) {
      return cpObj(a);
    }
  }

  //=========================================================================
  //=========================================================================
  addOrientationProc(proc) {
    if (APPLICATION.orientation && DEVICEORIENTATION) {
      return this.addListener({
        id: "window",
        type: "deviceorientationabsolute",
        capture: true,
        listener: (e) => {
          if ((proc != null)) {
            return proc({
              absolute: e.absolute,
              alpha: e.alpha,
              beta: e.beta,
              gamma: e.gamma
            });
          }
        }
      });
    }
  }

  removeOrientationProc() {
    return this.removeListener({
      id: "window",
      type: "deviceorientationabsolute"
    });
  }

  addMotionProc(proc) {
    if (APPLICATION.motion) {
      return this.addListener({
        id: "window",
        type: "devicemotion",
        capture: true,
        listener: (e) => {
          if ((proc != null)) {
            return proc({
              x: e.accelerationIncludingGravity.x,
              y: e.accelerationIncludingGravity.y,
              z: e.accelerationIncludingGravity.z
            });
          }
        }
      });
    }
  }

  removeMotionProc() {
    return this.removeListener({
      id: "window",
      type: "devicemotion"
    });
  }

  enum(arr) {
    var d, idx, j, len, ret;
    ret = {};
    for (idx = j = 0, len = arr.length; j < len; idx = ++j) {
      d = arr[idx];
      ret[d] = idx;
    }
    return ret;
  }

};

plustick = new plustick_core();
