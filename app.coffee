express = require('express')
app = express()

#bcrypt =  require 'bcrypt'
#bcrypt.genSalt 10, (error, salt) -> bcrypt.hash 'test', salt, (error, password) -> console.log(password)

app.use express.cookieParser()
app.use express.session { secret: 'asdf' }

app.use express.methodOverride()
app.use express.bodyParser()

r = require('rethinkdb')

r.connect { host: 'localhost', port: 48015, db: 'test' }, (err, conn) ->
  if (err) then throw err

  operators = (require './operators/operators')(conn)

  app.use operators.Flash
  app.use operators.LoadUser

  require('./controllers/user')(app, conn, operators)
  require('./controllers/application')(app, conn, operators)
  require('./controllers/data')(app, conn, operators)
  require('./controllers/client')(app, conn, operators)
  require('./controllers/main')(app, conn, operators)

app.listen 3000
