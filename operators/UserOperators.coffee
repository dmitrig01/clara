_ = require 'underscore'
fs = require 'fs'
r = require 'rethinkdb'
bcrypt = require 'bcrypt'

module.exports = (conn, operators) ->
  operators.LoadUser = (req, res, next) ->
    req.session.uid = 'e9340889-0741-4aee-b2f9-409c4573530b'
    if req.session.uid
      r.table('users').get(req.session.uid).run conn, (err, user) ->
        if !user then req.session.uid = req.user = null else req.user = user
        next()
    else
      req.session.uid = req.user = null
      next()

  operators.EnsureAuthenticated = (req, res, next) -> if !req.user then res.redirect '/login' else next()
  operators.EnsureNotAuthenticated = (req, res, next) -> if req.user then res.send 403 else next()

  operators.LogIn = (req, res, next) ->
    if !req.body.user || !req.body.pass
      req.flash 'error', 'Please specify a username and password'
      next()
    else
      r.table('users').filter(r.row('username').eq(req.body.user)).run conn, (err, cur) -> cur.toArray (err, data) ->
        user = data?[0]
        if !user then req.flash 'error', "Couldn't find a user with that username"; next()
        else bcrypt.compare req.body.pass, user.password, (e, r) ->
          if r then req.session.uid = user.id
          else req.flash 'error', "Bad password"
          next()

  operators.Register = (req, res, next) ->
    if !req.body.username || !req.body.email || !req.body.pass then req.flash 'error', 'Please fill out all required fields'; next()

    # TODO: Validate email address
    r.table('users').filter((user) -> user('name') == req.body.username || user('email') == req.body.email).run conn, (err, cur) -> cur.toArray (err, data) ->
      if data.length then req.flash 'error', "A user with that username or email address already exists"; next()
      else bcrypt.genSalt 10, (error, salt) -> bcrypt.hash req.body.pass, salt, (error, password) ->
        r.table('users').insert({ username: req.body.username, password, email: req.body.email, plan: 'adjunct', stripe: '' }).run conn, (err, result) ->
          req.session.uid = result.generated_keys[0]
          next()
          #req.invite.delete -> models.Application.find invite.application, (application) -> application.users.push '' + user._id; application.save -> res.redirect '/a/' + application._id

  operators.FindToken = (req, res, next) ->
    token = req.query.token ? req.param('token')
    if token
      r.table('applications').filter(r.row('tokens')('token').contains(token)).run conn, (err, curr) -> curr.next (err, application) ->
        if application
          req.token = token
          req.application = application
        else req.token = null
        next()
    else
      req.token = null
      next()

  operators.EnsureToken = (req, res, next) -> if !req.token then res.send 404 else next()

  operators.HandleToken = (req, res, next) ->
    if !req.token then return next()
    # Remove the token from the application
    req.application.tokens = _.reject req.application.tokens, (token) -> token.token == req.token
    # If the user isn't already part of the application, add them.
    if _.indexOf req.application.users, String req.session.uid == -1
      req.application.users.push String req.session.uid
    # Save the application
    r.table('applications').get(req.application.id).update(req.application).run conn, (err, cur) ->
      req.redirect = '/a/' + req.application.id # This might be kind of hacky. Oh well for now
      next()

  operators.Logout = (req, res, next) -> req.session.uid = null; next()
