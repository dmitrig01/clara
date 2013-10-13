#require View.Header
#require View.View

App.Router = Backbone.Router.extend

  routes:
    '': 'home'
    'view/:url': 'view'
    'users': 'users'

  home: -> @navigateView()

  navigateView: (pieces, navigate = true, override = false) ->
    if @_parts.view == -1 then @_parts.view = Application._('views').first().get('id')

    if override then @_viewUrl = pieces
    else @_viewUrl = _.extend(@_viewUrl ? {}, pieces)
    Backbone.history.navigate '#view/' + (@packUrl @_viewUrl), navigate

  _partOrder: ['view', 'page', 'data' ]
  _parts: { view: -1, page: 0, data: '' }
  packUrl: (pieces) ->
    url = []
    url.push pieces[part] ? @_parts[part] for part in @_partOrder
    url.join ':'
  unpackUrl: (url) ->
    @_viewUrl ?= {}
    pieces = url.split ':'
    @_viewUrl[part] = pieces[i] ? @_parts[part] for part, i in @_partOrder
    @_viewUrl

  view: (url) ->
    { view, page, data } = @unpackUrl(url)
    view = Application._('views')._(view)

    if !view then Backbone.history.navigate '', true
    else
      App.headerView.setView view
      App.headerView.render()
    
      if !App.mainView
        App.mainView = new App.View.View { el: $('#content').empty() }
      App.mainView.setView view, page, data
      App.mainView.render()

  users: ->
    App.headerView.setView '_users'
    App.headerView.render()

    userView = new App.View.Users { el: $('#content').empty() }
    userView.render()

    App.mainView = null
