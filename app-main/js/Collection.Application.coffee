#require Model.Application

App.Collection.Application = Backbone.Collection.extend
  model: App.Model.Application
  url: '/api/v0/applications'
