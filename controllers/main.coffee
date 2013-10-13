_ = require 'underscore'
fs = require 'fs'
express = require 'express'
r = require 'rethinkdb'

module.exports = (app, conn, operators) ->
  app.get '/', operators.EnsureAuthenticated, ((req, res, next) ->
    r.table('applications').filter(r.row('users').contains(req.user.id)).run conn, (err, cur) ->
      cur.toArray (err, data) ->
        res.template = 'Applications'
        res.templateData = { applications: data }
        next()),
    operators.Render

  app.post '/import', operators.EnsureAuthenticated, ((req, res, next) ->
    res.template = 'Import'
    res.templateData = { name: req.body.name, user: _.pick req.user, ['username', 'email', 'id'] }
    next()),
    operators.Render


  app.get '/a/:id', operators.EnsureAuthenticated, ((req, res, next) ->
    r.table('applications').get(req.param('id')).run conn, (err, app) ->
      res.template = 'Application'
      res.templateData = { app: app, user: _.pick req.user, ['username', 'email', 'id'] }
      next()),
    operators.Render

  app.use express.static 'public'
