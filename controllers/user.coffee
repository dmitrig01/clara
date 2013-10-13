module.exports = (app, conn, operators) ->
  app.get '/login', operators.EnsureNotAuthenticated, operators.ShowLogin, operators.Render

  app.post '/login',
    operators.EnsureNotAuthenticated,
    operators.FindToken,
    operators.LogIn,
    operators.Branch ((req, res, next) -> next(!!req.session.uid)),
      [ operators.HandleToken, operators.Redirect '/' ],
      [ operators.ShowLogin, operators.Render ]

  app.get '/register',
    operators.EnsureNotAuthenticated,
    operators.FindToken,
    #operators.EnsureToken,
    operators.ShowRegister,
    operators.Render

  app.post '/register',
    operators.EnsureNotAuthenticated,
    operators.FindToken,
    #operators.EnsureToken,
    operators.Register,
    operators.Branch ((req, res, next) -> next(!!req.session.uid)),
      [ operators.HandleToken, operators.Redirect '/' ],
      [ operators.ShowRegister, operators.Render ]

  app.get '/logout', operators.EnsureAuthenticated, operators.Logout, operators.Redirect '/'

  app.get '/invite/:token',
    operators.FindToken,
    operators.EnsureToken,
    (req, res, next) ->
      if req.session.uid then operators.HandleToken req, res, operators.Redirect '/' # It'll actually redirect to the application...
      else operators.Redirect '/register?token=' + req.token.token # req.params.token is not safe
