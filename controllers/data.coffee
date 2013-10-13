r = require 'rethinkdb'
ColumnTypes = require '../lib/ColumnTypes.coffee'
Step = require 'step'
_ = require 'underscore'
module.exports = (app, conn, operators) ->
  app.post '/api/v0/data/:app', operators.EnsureAuthenticated, (req, res) ->
    save req, res, 'insert'

  app.get '/api/v0/data/:app/:id', operators.EnsureAuthenticated, (req, res) ->
    r.table('data_' + req.param('app').replace(/[^a-z0-9]/g, '')).get(req.param('id')).run conn, (err, datum) -> res.send datum

  app.put '/api/v0/data/:app/:id', operators.EnsureAuthenticated, (req, res) ->
    save req, res, 'update'
      
  save = (req, res, op) ->
    r.table('applications').get(req.param('app')).run conn, (err, application) ->
      values = {}

      saveCalls = application.categories[0].columns.length
      saveCallback = ->
        if --saveCalls == 0
          res.contentType 'app.json'
          if op == 'update'
            r.table('data_' + req.param('app').replace(/[^a-z0-9]/g, '')).get(req.body.id).update(values).run conn, ->
              res.send values
          else
            r.table('data_' + req.param('app').replace(/[^a-z0-9]/g, '')).insert(values).run conn, (err, result) ->
              if err || result.errors then console.log 'Error'
              else res.send { id: result.generated_keys[0] }

      _.each application.categories[0].columns, (column) ->
        ColumnTypes[column.type].process req.body[column.id], (value) ->
          values[column.id] = value
          saveCallback()