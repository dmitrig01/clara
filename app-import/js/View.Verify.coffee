App.View.Verify = Backbone.View.extend
  events:
    'change input': -> @render()
    'submit form': (e) ->
      App.importInfo = @serialize()
      App.importView.stage = 'process'
      App.importView.render()
      false

  processData: ->
    @values =
      headers: []
      types: []
      firstRowHeaders: true
      data: []

    lines = App.data.split(/\n/).slice(0, 5)
    headers = lines[0].split(/\t/)

    for header in headers
      @values.headers.push header
      @values.types.push 'text'
    for line in lines
      @values.data.push line.split /\t/

  serialize: (modify = false) ->
    _t = this

    firstRowHeaders = @values.firstRowHeaders
    @values.firstRowHeaders = @$el.find('#firstRowHeaders').is(':checked')
    if @values.firstRowHeaders != firstRowHeaders
      if @values.firstRowHeaders
        @values.headers = @values.data[0]
      else
        @values.headers = Array(@values.data[0].length)
    else
      @values.headers = []
      @$el.find('tr.new-application-data-header input').each -> _t.values.headers.push $(@).val()
      
    @values.types = []
    @$el.find('tr.new-application-data-type select').each -> _t.values.types.push $(@).val()
      
    @values

  render: ->
    if !@values? then @processData()
    else @serialize true

    @values.columnTypes = @columnTypes
    @$el.empty().append App.Template.Verify @values
  columnTypes: (type) ->
    '<select>' + ('<option value="' + k + '"' + (if type == k then ' selected' else '') + '>' + v + '</option>' for k, v of App.ColumnTypes) + '</select>'
