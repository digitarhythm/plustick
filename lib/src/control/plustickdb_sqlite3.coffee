Database = require('better-sqlite3')
echo = require("ndlog").echo
fs = require("fs-extra")

DBDIR = "#{APPSDIR}/apps/database"

#==========================================================================
# convert sqlite3 style parameters to better-sqlite3 arguments
#   undefined / null   -> no parameter
#   [1, 2]             -> positional parameters
#   {$id: 1, ":n": 2}  -> named parameters (prefix removed)
#   1                  -> single positional parameter
#==========================================================================
__bindParams = (param) ->
  if (!param?)
    return []
  if (Array.isArray(param))
    return param
  if (typeof(param) == 'object')
    named = {}
    for key, val of param
      named[key.replace(/^[\$:@]/, "")] = val
    return [named]
  return [param]

class plustickdb_sqlite3
  constructor: ->

  init:(dbname) ->
    try
      path = "#{DBDIR}/#{dbname}"
      @_dbobject = new Database(path)
    catch e
      echo "error: #{e}"

  begin: ->
    return new Promise (resolve, reject) =>
      try
        @_dbobject.exec("BEGIN TRANSACTION")
        resolve
          err: 0
      catch e
        reject
          err: e

  commit: ->
    return new Promise (resolve, reject) =>
      try
        @_dbobject.exec("COMMIT")
        resolve
          err: 0
      catch e
        reject
          err: e

  run:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        stmt = @_dbobject.prepare(sql)
        if (stmt.reader)
          stmt.all(__bindParams(param)...)
        else
          stmt.run(__bindParams(param)...)
        resolve
          err: 0
      catch e
        reject
          err: e

  get:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        rows = @_dbobject.prepare(sql).all(__bindParams(param)...)
        resolve
          err: 0
          rows: rows
      catch e
        reject
          err: e

  all:(sql, param) ->
    return new Promise (resolve, reject) =>
      try
        rows = @_dbobject.prepare(sql).all(__bindParams(param)...)
        resolve
          err: 0
          rows: rows
      catch e
        reject
          err: e

  each:(sql, param, func) ->
    return new Promise (resolve, reject) =>
      try
        for row from @_dbobject.prepare(sql).iterate(__bindParams(param)...)
          func(row)
        resolve
          err: 0
      catch e
        reject
          err: e

  close: ->
    @_dbobject.close()

module.exports = plustickdb_sqlite3
