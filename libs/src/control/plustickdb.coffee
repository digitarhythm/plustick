sqlite3 = require('sqlite3').verbose()
echo = require("ndlog").echo
fs = require("fs-extra")

__appspath = fs.realpathSync(process.cwd())
__plustickpath = "#{fs.realpathSync(process.cwd())}/node_modules/plustick"
DBPATH = "#{__appspath}/apps/lib"

class plustickdb
  constructor:(kind)->
    @_dbkind = kind || "sqlite3"
    switch @_dbkind
      when "sqlite3"
        dbmod = require("#{__plustickpath}/libs/js/plustick_sqlite3.min.js")
      when "mysql"
        dbmod = require("#{__plustickpath}/libs/js/plustick_mysql.min.js")

    @DB = new dbmod()

  init:(dbname=undefined)->
    @DB.init(dbname)

  run:(sql, param)->
    @DB.run(sql, param)

  get:(sql, param)->
    @DB.get(sql, param)

  all:(sql, param)->
    @DB.all(sql, param)

  each:(sql, param, func)->
    @DB.each(sql, param, func)

  close:->
    @DB.close()

exports.plustickdb = plustickdb

