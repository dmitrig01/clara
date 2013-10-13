App.View.Enter = Backbone.View.extend
  events:
    'submit form': (e) ->
      App.data = @$el.find('textarea').val()
      App.importView.stage = 'verify'
      App.importView.render()
      false

  render: ->
    @$el.empty().append App.Template.Enter()