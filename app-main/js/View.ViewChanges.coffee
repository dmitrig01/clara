App.View.ViewChanges = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo @view, 'change save', @render
  events:
    'click #save': -> @view.save()
  render: ->
    @$el.empty().append App.Template.ViewChanges
      changed: Application.needsSave()