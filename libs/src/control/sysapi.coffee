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

router.post "/:endpoint", (req, res) ->
  endpoint = req.params.endpoint
  headers = req.headers
  data = req.body

  if (bind_router[endpoint]? && typeof(bind_router[endpoint]) == 'function')
    ret = bind_router[endpoint](headers, data)
    res.json(ret)

module.exports = router

