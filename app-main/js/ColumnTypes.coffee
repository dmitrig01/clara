App.ColumnTypes =
  text:
    name: 'Text'
    group: { full: 'Full text', first: 'First letter' }
    groupFormat: (type, group) -> _.escape group
    widget:
      html: (value) -> '<input type="text" value="' + (value ? '') + '" />'
      toValue: (field) -> field?.text ? '' # it gets _.escape'ed
      fromElement: (el) -> $(el).find('input').val()
    format:
      html: (field) -> if field?.text? then _.escape(field.text) else ''
      raw: (field) -> field?.text ? ''
    filter:
      widget: (filter, index) -> '<input type="text" class="filter-input" name="filter-' + index + '" value="' + filter.get('value') + '" id="filter-' + index + '" />'
      serialize: (el) -> { value: $(el).find('input').val() }

  number:
    name: 'Number'
    group: { 1: '1s', 10: '10s', 100: '100s', 1000: '1000s', 10000: '10000s' } 
    groupFormat: (type, group) -> (humanize.numberFormat group * type, 0) + 's'
    aggregators: { sum: 'Sum', avg: 'Average' }
    aggregatorFormat: (value) -> humanize.numberFormat value, (if value % 1 == 0 then 0 else 2)
    widget:
      html: (value) -> '<input type="text" value="' + (value ? '') + '" />'
      toValue: (field) -> field?.number ? ''
      fromElement: (el) -> $(el).find('input').val()
    format:
      html: (field) -> if field?.number? then humanize.numberFormat field.number, (if field.number % 1 == 0 then 0 else 2) else ''
      raw: (field) -> if field?.number? then humanize.numberFormat field.number else ''
    filter:
      widget: (filter, index) -> App.Template.FilterNumber { filter, index }
      serialize: (el) -> { op: $(el).find('.filter-op').val(), value: $(el).find('input').val() }

  date:
    name: 'Date/Time'
    group: { day: 'Day', month: 'Month', year: 'Year' }
    groupFormat: (type, group) ->
      if type == 'year' then group
      else if type == 'month' then App.monthNames[group % 100] + ' ' + Math.floor(group / 100)
      else App.monthNames[Math.floor(group/100) % 100] + ' ' + (humanize.ordinal group % 100) + ', ' + Math.floor(group/10000)

    widget:
      html: (value) -> '<input type="text" value="' + (value ? '') + '" />'
      toValue: (field) -> if field?.timestamp? then _.escape(humanize.date 'F jS, Y', field.timestamp) else ''
      fromElement: (el) -> $(el).find('input').val()
    format:
      html: (field) -> if field?.timestamp? then humanize.date 'F jS, Y', field.timestamp else ''
      raw: (field) -> if field?.timestamp? then humanize.date 'F jS, Y', field.timestamp else ''
    filter:
      widget: (filter, index) -> '<input type="text" class="filter-input" name="filter-' + index + '" value="' + filter.get('value') + '" id="filter-' + index + '" />'
      serialize: (el) -> { value: $(el).find('input').val() }

  location:
    name: 'Location'
    widget:
      html: (value) -> '<input type="text" value="' + (value ? '') + '" />'
      toValue: (field) -> field?.address ? ''
      fromElement: (el) -> $(el).find('input').val()
    format:
      html: (field) -> field?.address ? ''
      raw: (field) -> field?.address ? ''
