spawn = require('child_process').spawn

module.exports = (time, callback) ->
  pro = spawn __dirname + "/date.rb"

  pro.stdout.setEncoding('utf8')

  pro.stderr.on 'data', (data) -> callback String(data) ? 'Error'
  pro.stdout.on 'data', (data) ->
    pieces = data.split('-')
    if parseInt(pieces[0]) && parseInt(pieces[1])
      callback null, parseInt(pieces[0]), parseInt(pieces[1])
    else
      callback 'Couldn\'t parse date'

  pro.stdin.write time + '\n'
