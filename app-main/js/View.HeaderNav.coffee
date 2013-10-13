App.View.HeaderNav = Backbone.View.extend
  setView: (view) -> @view = view
  events:
    'click .view-add': ->
      name = prompt('Name:')
      console.log name, Application._('categories:default:columns').findOne(-> true).get('id')
      if !name then return false
      id = Application._('views').push
        name: name
        styleData:
          fields: [{ key: Application._('categories:default:columns').findOne(-> true).get('id') }]

      App.route.navigateView { view: id }, true, true
      false
    'dblclick .view': ->
      if name = prompt('Name:', @view.get('name'))
        @view._('name').set(name)
        @render()
      false

  render: ->
    @$el.empty().append App.Template.HeaderNav
      views: Application._('views')
      currentView: if @view.get? then @view.get('id') else @view