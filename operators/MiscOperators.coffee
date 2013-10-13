_ = require 'underscore'
fs = require 'fs'

module.exports = (conn, operators) ->
  operators.Redirect = (u) -> (req, res, next) ->
    if req.redirect then u = req.redirect
    res.redirect u
  operators.Flash = (req, res, next) ->
    req.session.flashes ?= []
    req.flash = (type, message) -> req.session.flashes.push { type, message }
    next()

  compose = operators.Compose = ->
    ops = Array.prototype.slice.call arguments, 0
    (req, res, next) ->
      iterate = (ops, i) ->
        if i >= ops.length && next?
          next()
        else if i < ops.length
          ops[i] req, res, -> iterate ops, i + 1
      iterate ops, 0

  operators.Branch = (condition, a, b) ->
    a = compose.apply null, a
    b = compose.apply null, b
    (req, res, next) ->
      condition req, res, (result) ->
        console.log(result)
        if result then a req, res, next
        else b req, res, next

