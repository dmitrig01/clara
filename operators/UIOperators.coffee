_ = require 'underscore'
fs = require 'fs'
r = require 'rethinkdb'
bcrypt = require 'bcrypt'

render = (tpl, data) -> _.template(String(fs.readFileSync './templates/' + tpl + '.ejs'), data)

preRender =
  Import: (data) ->
    head: """
    <script type="text/javascript" charset="utf-8" src="/js/jquery.js"></script>
    <script type="text/javascript" charset="utf-8" src="/js/underscore.js"></script>
    <script type="text/javascript" charset="utf-8" src="/js/backbone.js"></script>

    <script type="text/javascript" charset="utf-8" src="/app-import.js"></script>
    <script type="text/javascript" charset="utf-8">
      $(function() {
        App.user = #{ JSON.stringify(data.user) };
        App.name = #{ JSON.stringify(data.name) };
        App.initialize();
      });
    </script>"""
    data: data
  Application: (data) ->
    head: """
    <link rel="stylesheet" href="/jquery-modal/jquery.modal.css" type="text/css" media="screen" title="no title" charset="utf-8">
    <link type="text/css" rel="stylesheet" href="/jquery-dropdown/jquery.dropdown.css" />
    <link href='http://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.css' rel='stylesheet' />
    <!--[if lte IE 8]>
      <link href='http://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.ie.css' rel='stylesheet' >
    <![endif]-->
    <script type="text/javascript" charset="utf-8" src='http://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.js'></script>
    <script type="text/javascript" charset="utf-8" src="/js/jquery.js"></script>
    <script type="text/javascript" charset="utf-8" src="/js/underscore.js"></script>
    <script type="text/javascript" charset="utf-8" src="/js/backbone.js"></script>
    <script type="text/javascript" charset="utf-8" src="/js/humanize.js"></script>
    <script type="text/javascript" charset="utf-8" src="/jquery-dropdown/jquery.dropdown.js"></script>
    <script type="text/javascript" charset="utf-8" src="/jquery-modal/jquery.modal.js"></script>
    <script src="http://www.chartjs.org/docs/Chart.js" charset="utf-8"></script>
    <script type="text/javascript" charset="utf-8" src="/app-main.js"></script>
    <script type="text/javascript" charset="utf-8">
      $(function() {
        App.user = #{ JSON.stringify(data.user) };
        App.initialize(#{ JSON.stringify(data.app) });
      });
    </script>"""
    data: data
      
  Applications: (data) ->
    head: ''
    data: data

module.exports = (conn, operators) ->
  operators.Render = (req, res, next) ->
    template = res.template
    data = res.templateData

    data.flashes = req.session.flashes
    req.session.flashes = []

    { head, data } = (if preRender[template] then preRender[template] data else { head: '', data })
    body = render template, data
    res.send render 'Template', { head, body }

  operators.ShowRegister = (req, res, next) ->
    if req.application
      email = (_.find req.application.tokens, (token) -> token.token == req.token).email
    else
      email = ''
    res.template = 'Register'
    res.templateData = { token: req.token, email: email }
    next()

  operators.ShowLogin = (req, res, next) ->
    res.template = 'Login'
    res.templateData = {}
    next()

