fs = require 'fs'

module.exports = (conn) ->
  files = fs.readdirSync __dirname
  operators = {}
  (require __dirname + '/' + 'MiscOperators') conn, operators # Contains helpers for other operators
  for file in files
    if file != 'operators.coffee' && file != 'MiscOperators.coffee'
      (require __dirname + '/' + file) conn, operators
  operators