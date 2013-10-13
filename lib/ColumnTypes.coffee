DateParser = require './date'
humanize = require 'humanize'
r = require 'rethinkdb'
request = require 'request'

module.exports =
  text:
    columns: [ 'text' ]
    sort: { column: 'text' }
    toRaw: (field) -> field?.text ? ''
    fromRaw: (raw) -> raw
    process: (value, callback) -> callback { text: String(value) }
    filter: (filter, query, callback) ->
      if filter.value
        query = query.filter (row) -> row(filter.key)('text').match('(?i)' + filter.value)
      callback query
    group: (data, field, type) ->
      if type == 'first'
        r.expr("aAAbBBcCCdDDeEEfFFgGGhHHiIIjJJkKKlLLmMMnNNoOOpPPqQQrRRsSStTTuUUvVVwWWxXXyYYzZZ").match(
          data(field)('text').match('^.')('str').add('(.)')
        )('groups').nth(0)('str')
      else
        data(field)('text')
  number:
    columns: [ 'number' ]
    sort: { column: 'number' }
    toRaw: (field) -> field?.number ? ''
    fromRaw: (raw) -> raw
    process: (value, callback) -> callback { number: parseFloat String(value).replace /[^\d\.]/g, '' }
    filter: (filter, query, callback) ->
      if filter.value
        callback query.filter(
          r.row(filter.key)('number')[filter.op ? 'eq'](parseInt filter.value.replace(/[^\d\.]/, ''))
        )
      else callback query
    group: (data, field, type) -> r.json(data(field)('number').div(parseInt type).coerceTo("string").match("[0-9]+")('str'))
  date:
    columns: [ 'timestamp', 'year', 'month', 'day' ]
    sort: { column: 'timestamp' }
    toRaw: (field) -> if field?.timestamp then humanize.date 'F jS, Y', field.timestamp else ''
    fromRaw: (raw) -> raw
    process: (value, callback) ->
      DateParser value, (err, min, max) ->
        if err
          timestamp = Math.round(new Date().getTime() / 1000)
        else
          timestamp = min + ((max-min)/2)
        date = new Date(timestamp * 1000)
        string = ''
        padAdd = (int, pad) -> parseInt(if !pad || int > 9 then string += int else string += '0' + int)
        callback
          timestamp: timestamp
          year: padAdd date.getFullYear()
          month: (padAdd date.getMonth(), true)
          day: (padAdd date.getDate(), true)
    filter: (filter, query, callback) ->
      if filter.value
        DateParser filter.value, (err, min, max) ->
          if !err
            callback query.filter(
              r.row(filter.key)('timestamp').ge(min)
            ).filter(
              r.row(filter.key)('timestamp').lt(max)
            )
          else callback query
      else callback query
    group: (data, field, type) -> data(field)(type)
  location:
    columns: [ 'address', 'latitude', 'longitude' ]
    toRaw: (field) -> field.address
    fromRaw: (raw) -> raw
    process: (value, callback) ->
      request {uri: "https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=" + encodeURIComponent(value), json:true}, (err, resp, json) ->
        if json.results.length
          callback
            latitude: json.results[0].geometry.location.lat
            longitude: json.results[0].geometry.location.lng
            address: json.results[0].formatted_address
        else
          callback { address: value }
