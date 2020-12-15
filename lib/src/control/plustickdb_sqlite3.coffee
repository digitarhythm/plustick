sqlite3 = require('sqlite3').verbose()
echo = require("ndlog").echo
fs = require("fs-extra")

DBDIR = "#{APPSDIR}/apps/lib"

class plustickdb_sqlite3
  constructor: ->

  init:(dbname) ->
    try
      path = "#{DBDIR}/#{dbname}"
      @_dbobject = new sqlite3.Database(path)
    catch e
      echo "error: #{e}"

  begin: ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare("BEGIN TRANSACTION")
        stmt.run param, (err, rows) =>
          #stmt.finalize()
          resolve
            err: 0
      catch e
        reject
          err: e

  commit: ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare("COMMIT")
        stmt.run param, (err, rows) =>
          #stmt.finalize()
          resolve
            err: 0
      catch e
        reject
          err: e

  run:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare(sql, param)
        stmt.run param, (err, rows) =>
          #stmt.finalize()
          resolve
            err: 0
      catch e
        reject
          err: e

  get:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare(sql)
        stmt.all param, (err, rows) =>
          #stmt.finalize()
          resolve
            err: 0
            rows: rows
      catch e
        reject
          err: e

  all:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare(sql)
        stmt.all param, (err, rows) =>
          #stmt.finalize()
          resolve
            err: 0
            rows: rows
      catch e
        reject
          err: e

  each:(sql, param, func) ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare(sql, param)
        stmt.each (err, rows) =>
          func(rows)
        stmt.finalize()
        resolve
          err: 0
      catch e
        reject
          err: e

  close: ->
    @_dbobject.close()

module.exports = plustickdb_sqlite3

