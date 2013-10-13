types =
  object: (items) -> { type: 'object', items: items }
  list: (items) -> { type: 'list', items: items }
  keyedList: (items) -> { type: 'keyedList', items: items }
  value: (def) -> { type: 'value', def }

DataModel = types.object
  _idOffset: types.value(0)
  views: types.keyedList types.object
    styleData: types.object
      fields: types.list types.object
        key: types.value('')
        aggregator: types.value('')
      chartKey: types.value('_count')
    style: types.value('table')
    sort: types.object
      direction: types.value()
      column: types.value()
    name: types.value()
    id: types.value()
    group: types.object
      type: types.value()
      column: types.value()
    filters: types.list types.object
      key: types.value()
      value: types.value('')
      op: types.value('eq')
    aggregators: types.keyedList types.object
      id: types.value()
      type: types.value()
      column: types.value()
  users: types.list types.value()
  tokens: types.list types.object
    token: types.value()
    email: types.value()
  name: types.value()
  id: types.value()
  categories: types.keyedList types.object
    id: types.value()
    columns: types.keyedList types.object
      id: types.value()
      type: types.value()
      name: types.value()

class Model
  constructor: (data, dataModel = null, selectorHistory = [], root = this) ->
    @data = data
    if dataModel then @dataModel = dataModel
    @selectorHistory = selectorHistory
    @root = root

  select: (data, dataModel, selector) ->
    _default = (dataModel) -> switch dataModel.type
      when 'value' then dataModel.def ? ''
      when 'object' then {}
      when 'list' then []
      when 'keyedList' then []

    if selector.length == 0
      if typeof dataModel == 'undefined' then throw 'err'
      def = _default dataModel
      return { data: data ? def, dataModel }

    currentSelector = selector.shift()

    if dataModel.type == 'value'
      { data: data[currentSelector] ?= dataModel.def, dataModel }
    else if dataModel.type == 'object'
      @select (data[currentSelector] ?= _default dataModel.items[currentSelector]), dataModel.items[currentSelector], selector
    else if dataModel.type == 'list'
      @select (data[parseInt currentSelector] ?= _default dataModel.items), dataModel.items, selector
    else if dataModel.type == 'keyedList'
      @select (_.find data, (datum) -> String(datum.id) == currentSelector), dataModel.items, selector

  _new: (data, children = false, history = null) ->
    new @__type(data, (children ? @dataModel), (if history then @selectorHistory.concat(history) else @selectorHistory), @root)

  _: (selector) ->
    { data, dataModel } = @select @data, @dataModel, String(selector).split ':'
    @_new data, dataModel, String(selector).split ':'

  find: (cb) ->
    items = _.filter @data, (currentItem, key) =>
      cb @_new currentItem, @dataModel.items, currentItem.id ? key

    @_new items

  findOne: (cb) ->
    item = null
    result = _.find @data, (currentItem, key) =>
      cb item = @_new(currentItem, @dataModel.items, currentItem.id ? key)
    if result then item

  toJSON: -> @data

  first: -> @findOne -> true
  each: (cb) ->
    _.each @data, (value, key) =>
      k = value.id ? key
      selection = @_new value, @dataModel.items, k
      cb selection, key

  get: (selector) -> if selector then @_(selector).get() else @data
  needsSave: -> !!@root._needsSave

  _inTransaction: (callback) ->
    commit = false
    if !@root._transaction
      @root.transaction()
      commit = true
    ret = callback()
    if commit then @commit()
    ret

  set: (value) -> @_inTransaction =>
    selectors = @selectorHistory.slice(0)
    key = selectors.pop()
    @root._(selectors.join(':'))._set(key, value)
    @trigger 'change'

    #@root._changes ?= {}
    #@root._changes[@selectorHistory.join(':')] = [ 'set', value ]

    @root._needsSave = true

  _set: (key, value) ->
    # Rely on JavaScript not cloning arrays and objects
    @data[key] = value

  push: (value) -> @_inTransaction =>
    #@root._changes ?= {}
    #@root._changes[@selectorHistory.join(':')] = [ 'push', value ]

    @data ?= []
    if @dataModel.type == 'list'
      @data.push value
    else if @dataModel.type == 'keyedList'
      @root.data._idOffset ?= 0
      ret = value.id = ++@root.data._idOffset
      @data.push value
    else throw 'Can\'t push to something that\'s not a list'
    @trigger 'change'
    @root._needsSave = true
    return ret ? null

  size: -> _.size(@data)

  remove: (iterator) -> @_inTransaction =>
    if typeof iterator != 'function'
      #@root._changes ?= {}
      #@root._changes[@selectorHistory.join(':')] = [ 'remove', iterator ]

      _id = iterator
      if @dataModel.type == 'list' or @dataModel.type == 'object' then iterator = (v, k) -> k == _id
      else if @dataModel.type == 'keyedList' then iterator = (v, k) -> v.id == _id

    toRemove = []
    _.each @data, (v, k) -> if iterator(v, k) then toRemove.push k

    if @dataModel.type == 'object' then delete @data[k] for k in toRemove
    else @data.splice k, 1 for k in toRemove.reverse()

    @trigger 'change'
    @root._needsSave = true

  on: (actions, callback, context) ->
    @root._listeners ?= {}
    _.each actions.split(' '), (action) =>
      @root._listeners[action] ?= []
      @root._listeners[action].push [callback, context]

  # Remove one or many callbacks. If `context` is null, removes all
  # callbacks with that function. If `callback` is null, removes all
  # callbacks for the event. If `name` is null, removes all bound
  # callbacks for all events.
  off: (name, callback, context) ->
    if !name && !callback && !context then @root._listeners = {}; return

    names = if name then [name] else _.keys(@root._listeners)
    for name in names
      if events = @root._listeners[name]
        @root._listeners[name] = retain = []
        if callback || context
          for ev in events
            if (callback && callback != ev[0]) ||
               (context && context != ev[1])
              retain.push(ev);
        if !retain.length then delete @root._listeners[name]

  transaction: -> @root._transaction = true
  commit: ->
    #App.route.navigateView({ changes: @root.serialize() }, false)
    @root._transaction = false
    for callback in _.uniq(@root._currentCallbacks, false, (cb) -> cb[0])
      callback[0].apply(callback[1], callback[2])
    @root._currentCallbacks = []

  trigger: (action) ->
    args = Array.prototype.slice.call arguments, 1
    pieces = @selectorHistory.slice(0)
    pieces.unshift action

    possibilities = []
    while pieces.length
      possibilities.push pieces.join ':'
      if pieces.length > 2
        r = pieces[2]
        pieces[2] = '*'
        possibilities.push pieces.join ':'
        pieces[2] = r

      if pieces.length > 4
        s = pieces[4]
        pieces[4] = '*'
        possibilities.push pieces.join ':'
        r = pieces[2]
        pieces[2] = '*'
        possibilities.push pieces.join ':'
        pieces[2] = r
        pieces[4] = s

      pieces.pop()

    @root._currentCallbacks ?= []
    @root._listeners ?= {}
    for possibility in possibilities
      if @root._listeners[possibility]
        for callback in @root._listeners[possibility]
          callback[2] = args
          @root._currentCallbacks.push callback

  url: -> '/api/v0/applications' + (if !@root.isNew? then '/' + @root.get('id') else '')
  save: (callback) -> @_inTransaction =>
    Backbone.sync (if @root.isNew? then 'create' else 'update'), @root,
      success: (resp) =>
        if resp.id then @root.data.id = resp.id
        callback()
    @root._needsSave = false
    @root.trigger 'save'

  '''
  serialize: ->
    if !@root._changes? || !_.size(@root._changes) then return ''
    pieces = []
    for selector, change of @root._changes
      pieces.push selector.length + change[0][0] + selector + JSON.stringify(change[1])
    btoa pieces.join '|'
  unserialize: (str) ->
    @transaction()
    if str.length
      for piece in atob(str).split('|')
        parts = piece.match /^(\d+)(.)(.+)$/
        action = switch parts[2]
          when 'p' then 'push'
          when 'r' then 'remove'
          when 's' then 'set'
        selector = parts[3].substring(0, parseInt(parts[1]))
        value = JSON.parse(parts[3].substring(parseInt(parts[1])))

        @_(selector)[action](value)
    @commit()'''


class App.Model.Application extends Model
  dataModel: DataModel
  run: (page, callback) ->
    if @selectorHistory.length == 2 && @selectorHistory[0] == 'views'
      if window.Application.needsSave()
        $.ajax
          dataType: 'json'
          url: '/api/v0/applications/' + window.Application.get('id') + '/view?page=' + page
          type: 'post'
          contentType: 'application/json; charset=UTF-8'
          data: JSON.stringify(@toJSON())
          success: (data) -> callback data
      else
        $.getJSON '/api/v0/applications/' + window.Application.get('id') + '/view/' + @data.id + '?page=' + page, (data) -> callback data
  type: (test) ->
    if @selectorHistory.length == 4 && @selectorHistory[0] == 'categories' && @selectorHistory[2] == 'columns'
      App.ColumnTypes[@data.type]

App.Model.Application.prototype.__type = App.Model.Application

