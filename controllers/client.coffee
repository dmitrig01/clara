_ = require 'underscore'
fs = require 'fs'
cs = require 'coffee-script'
r = require 'rethinkdb'

module.exports = (app, conn, operators) ->
  app.get '/app-main.js', operators.EnsureAuthenticated, operators.ClientCode('app-main')
  app.get '/app-import.js', operators.EnsureAuthenticated, operators.ClientCode('app-import')