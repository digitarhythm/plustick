sqlite3 = require('sqlite3').verbose()
echo = require("ndlog").echo
fs = require("fs-extra")

__appspath = fs.realpathSync(process.cwd())

class plustickdb
  constructor:(kind) ->
    @_dbkind = kind || "sqlite3"
    switch @_dbkind
      when "sqlite3"
        dbmod = require("#{PLUSTICKLIBS}/plustickdb_sqlite3.min.js")
      when "mysql"
        dbmod = require("#{PLUSTICKLIBS}/plustickdb_mysql.min.js")

    @DB = new dbmod()

  init:(dbname=undefined) ->
    @DB.init(dbname)

  run:(sql, param) ->
    @DB.run(sql, param)

  get:(sql, param) ->
    @DB.get(sql, param)

  all:(sql, param) ->
    @DB.all(sql, param)

  each:(sql, param, func) ->
    @DB.each(sql, param, func)

  close: ->
    @DB.close()

module.exports = plustickdb

