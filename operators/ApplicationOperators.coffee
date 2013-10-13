_ = require 'underscore'
r = require 'rethinkdb'
ColumnTypes = require '../lib/ColumnTypes.coffee'
sendgrid = (require 'sendgrid')('dmitrig01', 'dm1trizone')

module.exports = (conn, operators) ->
  operators.LoadApplication = (req, res, next) ->
    r.table('applications').get(req.param('app')).run conn, (err, application) ->
      req.application = application
      next()

  operators.ApplicationList = (req, res) ->
    r.table('applications').filter(r.row('users').contains(req.user.id)).run conn, (err, cur) ->
      res.contentType 'app.json'
      cur.toArray (err, data) ->
        res.send data

  operators.ApplicationNew = (req, res) ->
    r.table('applications').insert(req.body).run conn, (err, result) ->
      r.tableCreate('data_' + result.generated_keys[0].replace(/[^a-z0-9]/g, '')).run conn, ->
      res.contentType 'app.json'
      if err || result.errors then console.log 'Error'
      else res.send { id: result.generated_keys[0] }

  operators.ApplicationSend = (req, res) ->
    res.contentType 'app.json'
    res.send req.application

  operators.ApplicationDelete = (req, res) ->
    r.table('applications').get(req.param('app')).delete().run conn, (err, cur) ->
      res.contentType 'app.json'
      if err || cur.errors then console.log 'Error'
      else res.send {}

  # When an application is changed, find column changes
  operators.FindApplicationChanges = (req, res, next) ->
    # No adding columns for now
    newApplication = req.body
    oldApplication = req.application

    req.columnChanges = []; req.columnDeletions = []
    _.each oldApplication.categories[0].columns, (oldColumn) ->
      newColumn = _.find(newApplication.categories[0].columns, (nc) -> nc.id == oldColumn.id)
      if !newColumn
        req.columnDeletions.push oldColumn.id
      else if newColumn.type != oldColumn.type
        req.columnChanges.push
          key: oldColumn.id
          oldType: ColumnTypes[oldColumn.type]
          newType: ColumnTypes[newColumn.type]

    req.addedTokens = []
    _.each newApplication.tokens, (token) ->
      oldToken = _.find oldApplication.tokens, (ot) -> ot.email == token.email
      if !oldToken then req.addedTokens.push token

    next()

  operators.ProcessDeletedColumns = (req, res, next) ->
    if !req.columnDeletions.length then return next()

    rows = r.row
    (rows = rows.without col) for col in req.columnDeletions
    r.table('data_' + req.application.id.replace(/[^a-z0-9]/g, '')).replace(rows).run conn, -> next()

  operators.ProcessChangedColumns = (req, res, next) ->
    if !req.columnChanges.length then return next()

    r.table('data_' + req.application.id.replace(/[^a-z0-9]/g, '')).run conn, (err, curr) ->
      if err then console.log 'Error'

      endCalls = 1
      endCallback = -> if --endCalls == 0 then next()

      curr.each ((err, data) ->
        endCalls++
        save = _.after req.columnChanges.length,
          -> r.table('data_' + req.application.id.replace(/[^a-z0-9]/g, '')).get(data.id).update(data).run(conn, endCallback)
        for column in req.columnChanges then do (column) ->
          column.newType.process column.newType.fromRaw(column.oldType.toRaw(data[column.key])), (newValue) ->
            data[column.key] = newValue
            save()
        ), endCallback

  operators.SendEmails = (req, res, next) ->
    _.each req.addedTokens, (token) ->
      sendgrid.send {
        to:       token.email,
        from:     'dmitri@boldium.com',
        subject:  'Hello there!',
        text:     'You were invited to use my app. Go to http://localhost:3000/invite/' + token.token
      }, ( -> )
    next()

  operators.SaveApplication = (req, res, next) ->
    r.table('applications').get(req.param('app')).update(req.body).run conn, (err, cur) ->
      res.contentType 'app.json'
      if err || cur.errors then console.log 'Error'
      else res.send {}

  operators.SendUsers = (req, res) ->
    query = r.table('users')
    query = query.getAll.apply query, req.application.users
    query.run conn, (err, curr) -> curr.toArray (err, data) ->
      res.contentType 'app.json'
      # Sanitize data
      res.send _.map data, (user) -> { username: user.username, id: user.id, email: user.email }

  operators.GetViewFromBody = (req, res, next) ->
    req.view = req.body
    next()

  operators.GetView = (req, res, next) ->
    req.view = _.find req.application.views, ((view) -> view.id.toString() == req.param('view').toString())
    next()

  # Apply filters
  operators.RunViewFilters = (req, res, next) ->
    view = req.view
    query = r.table('data_' + req.application.id.replace(/[^a-z0-9]/g, ''))
    actions = [ (n) -> n(query) ]

    view.filters ?= []
    for filter in view.filters then do (filter) ->
      column = _.find req.application.categories[0].columns, ((column) -> column.id.toString() == filter.key.toString())
      actions.push (n, query) ->
        ColumnTypes[column.type].filter filter, query, n

    (_.reduceRight actions, _.wrap, (query) ->
      req.view.query = query
      next()
    )()

  # Group
  operators.RunViewGroup = (req, res, next) ->
    view = req.view
    query = view.query
    if !view.group?.column then return next()
    column = _.find req.application.categories[0].columns, ((column) -> String(column.id) == String(view.group.column))
    req.view.query = query.map((data) -> { id: data('id'), _group: ColumnTypes[column.type].group data, String(column.id), view.group.type }).eqJoin('id', r.table('data_' + req.application.id.replace(/[^a-z0-9]/g, ''))).zip()
    next()

  # Count and aggregate
  operators.RunViewCount = (req, res, next) ->
    view = req.view
    query = view.query

    aggregators = view.aggregators? && _.size(view.aggregators)

    # Since, at this point, the only types of aggregation are sum and average, and both need a sum
    # and we need a count anyway, just take a sum and a count
    if view.group?.column || aggregators
      fieldsToSum = _(view.aggregators).chain().pluck('column').uniq().filter((field) -> field?).value()
      map = (data) ->
        ret = { _count: 1 }
        ret[field] = data(field)('number') for field in fieldsToSum
        ret
      reduce = (acc, data) ->
        ret = { _count: acc('_count').add(data('_count')) }
        ret[field] = acc(field).add(data(field)) for field in fieldsToSum
        ret

    if view.group?.column
      query = query.groupedMapReduce r.row('_group'), map, reduce
    else if aggregators
      query = query.map(map).reduce(reduce)
    else
      query = query.count()

    query.run conn, (err, count) ->
      req.view.result = {}

      processAggregators = (row) ->
        results = {}
        for aggregate in view.aggregators ? []
          if aggregate.type == 'sum'
            results[aggregate.id] = row[aggregate.column]
          else
            results[aggregate.id] = row[aggregate.column] / row._count
        results._count = row._count
        results

      if view.group?.column
        req.view.result.totalCount = _.reduce(count, ((memo, row) -> memo + row.reduction._count), 0)
        req.view.result.aggregators = _(count)
          .chain()
          .map((value) -> value.aggregate = processAggregators(value.reduction); value)
          .reduce(((memo, row) -> memo[row.group] = row.aggregate; memo), {})
          .value()
 
        req.view.result.aggregatorTotals = processAggregators _(count).reduce ((memo, row) ->
          for k, v of row.reduction
            if memo[k] then memo[k] += v else memo[k] = v
          memo), {}
      else if aggregators
        req.view.result.totalCount = count._count
        req.view.result.aggregatorTotals = processAggregators count
      else
        req.view.result.totalCount = count
      next()

  # Sort
  operators.RunViewSort = (req, res, next) ->
    view = req.view
    query = view.query
    count = view.count

    sorts = []
    if view.group
      sorts.push r.asc('_group')
    if view.sort && view.sort.column && view.sort.direction
      column = _.find req.application.categories[0].columns, ((column) -> column.id.toString() == view.sort.column.toString()) # Validate the column
      if column
        sorts.push r[(if view.sort.direction == 'asc' then 'asc' else 'desc')](String(column.id))
    if sorts.length
      req.view.query = query.orderBy.apply query, sorts
    next()

  # Finalize
  operators.RunViewFinal = (req, res, next) ->
    view = req.view
    query = view.query
    # Make sure to do this after ordering
    if view.style == 'table'
      page = parseInt(req.query.page) || 0
      query = query.skip(page * 20).limit 20 # This value is mirrored in client/js/Initialize.coffee
    if view.style == 'calendar'
      if req.query.page
        total = parseInt req.query.page
        year = total % 10000
        month = (total - year)/10000
      else
        month = (new Date()).getMonth()
        year = (new Date()).getFullYear()
      startDate = (new Date(year, month, 1, 0, 0, 0, 0)).getTime() / 1000
      endDate = (new Date(year, month + 1, 1, 0, 0, 0, 0)).getTime() / 1000
      if !(field = view.styleData.dateField)
        field = (_.find req.application.categories[0].columns, ((column) -> column.type == 'date')).id
      query = query.filter(r.row(String field)('timestamp').ge(startDate)).filter(r.row(String field)('timestamp').lt(endDate))

    res.contentType 'app.json'
    if view.style == 'chart'
      result = { aggregators: view.result.aggregators ? {} }
      res.send result
    else
      query.run conn, (err, cur) ->
        if err then res.send err
        else
          cur.toArray (err, data) ->
            result = { data, count: view.result.totalCount, aggregators: view.result.aggregators ? {}, aggregatorTotals: view.result.aggregatorTotals ? {} }
            res.send result

  operators.RunView = operators.Compose operators.RunViewFilters,
    operators.RunViewGroup,
    operators.RunViewCount,
    operators.RunViewSort,
    operators.RunViewFinal



  '''
  operators.ParseMetadata = (req, res, next) ->
    req.session.metadata = {}
    data = req.session.data = req.session.data.replace("\r", "\n").replace(/\n[\s]+/g, "\n").trim()
    done = false
    startIndex = 0
    data_length = data.length
    getLine = ->
      return if done
      i = data.indexOf "\n", startIndex
      done = (i == -1)
      i = data_length if done
      d = data.substring startIndex, i
      startIndex = i + 1
      d

    # Count lines
    req.session.metadata.lineCount = data.match(/\n+/g).length # This includes the header
    lines = []
    for i in [0 .. Math.min(10, req.session.metadata.lineCount)]
      if g = getLine()
        lines.push g

    j = "\t," + (lines.join "\n") # Add to the beginning so that the lengths don't come out as null in the next line
    req.session.metadata.separators = (if j.match(/,/g).length > j.match(/\t/g).length then { separator: ',', delimiter: '"' } else { separator: "\t", delimiter: '' })
    for line, i in lines
      lines[i] = csvLine2Array line, req.session.metadata.separators
    req.session.metadata.lines = lines
    req.session.metadata.fields = Math.round _.reduce(lines, ((memo, line)-> memo + line.length), 0) / lines.length
    req.session.metadata.headers = req.session.metadata.lines.shift()
    # Eventually guess data type
    next()


    
'''