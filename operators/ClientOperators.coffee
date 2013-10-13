_ = require 'underscore'
fs = require 'fs'
cs = require 'coffee-script'
r = require 'rethinkdb'

module.exports = (conn, operators) ->
  operators.ClientCode = (app_name) -> (req, res) ->
    result = "window.App = { Model: {}, Collection: {}, View: {}, Data: {}, Template: {} }; window.Data = {}\n"

    for file in fs.readdirSync './' + app_name + '/templates'
      if (file.indexOf '.') != 0
        result += "App.Template['" + file.split('.').reverse().splice(1).reverse().join('.') + "'] = `" + _.template(String(fs.readFileSync './' + app_name + '/templates/' + file)).source + "`\n"

    files = []
    added = []
    for file in fs.readdirSync './' + app_name + '/js'
      if (file.indexOf '.') != 0
        dependencies = []
        data = String(fs.readFileSync './' + app_name + '/js/' + file)
        while data.length > 0 && data.indexOf("#require") == 0
          d = data.split "\n"
          dependencies.push d.shift().split(' ').pop()
          data = d.join "\n"
        if dependencies.length == 0
          added.push file.split('.').reverse().splice(1).reverse().join('.')
          result += data + "\n"
        else
          files.push [ file.split('.').reverse().splice(1).reverse().join('.'), data, dependencies ]

    while files.length
      remove = []

      for [ name, data, dependencies ], i in files
        if !_.difference(dependencies, added).length
          remove.push i
          added.push name
          result += data + "\n"
      files.splice i, 1 for i in remove.reverse()

    res.contentType 'app.js'

    try
      js = cs.compile result
    catch err
      console.log err
      console.log result.split("\n")[err.location.first_line]
    res.send js
