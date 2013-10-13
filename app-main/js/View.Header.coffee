#require View.HeaderNav

App.View.Header = Backbone.View.extend
  nav: new App.View.HeaderNav
  setView: (view) ->
    @view = view
    @nav.setView view
  render: ->
    @$el.empty().append App.Template.Header()
    @nav.setElement @$el.find '#navigation'
    @nav.render()