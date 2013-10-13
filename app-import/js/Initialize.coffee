#require Model.Application

App.ColumnTypes =
  text: 'Text'
  number: 'Number'
  date: 'Date/Time'
  location: 'Location'

App.initialize = (name) ->
  window.Application = new App.Model.Application
    categories: [ { id: 'default', columns: [] } ]
    name: App.name
    _idOffset: 1
    views: [ { id: 0, name: "Untitled View" } ]
    users: [ App.user.id ]
  App.importView = new App.View.Import { el: $('#content') }
  App.importView.render()

  