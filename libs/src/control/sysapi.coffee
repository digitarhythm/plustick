express = require("express")
router = express.Router()
Promise = require("bluebird")
path = require("path")
config = require("config")
fs = require("fs-extra")
echo = require("ndlog").echo
bind_router = global.BIND_ROUTER

router.use(express.json())
router.use(express.urlencoded({ extended: true }))

router.all "/:endpoint", (req, res) ->
  method = req.method
  endpoint = req.params.endpoint
  data = req.body
  headers = req.headers
  headers['method'] = method

  if (bind_router[endpoint]? && typeof(bind_router[endpoint]) == 'function')
    bind_router[endpoint](headers, data).then (ret)=>
      res.json(ret)

module.exports = router

