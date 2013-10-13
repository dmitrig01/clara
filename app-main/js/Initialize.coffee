#require Router
#require Model.Application

App.pageSize = 20.0
App.monthNames = [
  "January"
  "February"
  "March"
  "April"
  "May"
  "June"
  "July"
  "August"
  "September"
  "October"
  "November"
  "December"
]

App.initialize = (application) ->
  window.Application = new App.Model.Application(application)
  window.OriginalApplication = Application.clone()

  App.headerView = new App.View.Header { el: '#header' }

  App.route = new App.Router
  Backbone.history.start()

  