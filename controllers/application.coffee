ColumnTypes = require '../lib/ColumnTypes.coffee'
r = require 'rethinkdb'
_ = require 'underscore'

module.exports = (app, conn, operators) ->
  app.get '/api/v0/applications',
    operators.EnsureAuthenticated,
    operators.ApplicationList

  app.post '/api/v0/applications',
    operators.EnsureAuthenticated,
    operators.ApplicationNew

  app.get '/api/v0/applications/:app',
    operators.EnsureAuthenticated,
    operators.LoadApplication,
    operators.ApplicationSend

  app.put '/api/v0/applications/:app',
    operators.EnsureAuthenticated,
    operators.LoadApplication,
    operators.FindApplicationChanges,
    operators.ProcessDeletedColumns,
    operators.ProcessChangedColumns,
    operators.SendEmails,
    operators.SaveApplication

  app.delete '/api/v0/applications/:app',
    operators.EnsureAuthenticated,
    operators.ApplicationDelete

  app.get '/api/v0/applications/:app/users',
    operators.EnsureAuthenticated,
    operators.LoadApplication,
    operators.SendUsers

  app.post '/api/v0/applications/:app/view',
    operators.EnsureAuthenticated,
    operators.LoadApplication,
    operators.GetViewFromBody,
    operators.RunView

  app.get '/api/v0/applications/:app/view/:view',
    operators.EnsureAuthenticated,
    operators.LoadApplication,
    operators.GetView,
    operators.RunView
  

