App.Model.Data = Backbone.Model.extend
  urlRoot: -> '/api/v0/data/' + Application.get('id')