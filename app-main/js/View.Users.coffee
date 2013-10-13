App.View.Users = Backbone.View.extend
  events:
    'submit form': ->
      token = ""
      possibilities = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
      token += possibilities.charAt Math.floor(Math.random() * possibilities.length) for [0..30]

      ns = Application._needsSave
      clone = OriginalApplication.clone()
      clone._('tokens').push
        token: token
        email: @$el.find('#name').val()
      clone.save()

      Application._('tokens').push
        token: token
        email: @$el.find('#name').val()
      Application._needsSave = ns
      @render()

      false
  render: ->
    _render = =>
      @$el.empty().append App.Template.Users
        users: @users
        tokens: Application._('tokens')

    if !@users
      Application.getUsers (users) =>
        @users = users
        _render()
    else _render()
