#require View.ViewTable
#require View.ViewDataEditor
#require View.ViewStylePicker
#require View.ViewFilters
#require View.ViewChanges

App.View.View = Backbone.View.extend
  dataEditor: new App.View.ViewDataEditor
  stylePicker: new App.View.ViewStylePicker
  filters: new App.View.ViewFilters
  changes: new App.View.ViewChanges
  setBody: ->
    if @body then @body.undelegateEvents().stopListening()
    @body = switch @view.get('style')
      when 'table'    then new App.View.ViewTable
      when 'map'      then new App.View.ViewMap
      when 'chart'    then new App.View.ViewChart
      when 'calendar' then new App.View.ViewCalendar

    @body.setView @view
    if @$el then @body.setElement @$el.find '#view-body'

  events:
    'click #column-add': ->
      view = new App.View.ColumnEdit
      view.setColumn()
      view.render()
      false

  setView: (view, page, data) ->
    changeStyle = (!@view? || @view.get('style') != view.get('style'))

    @view = view
    @page = page

    @listenTo Application, 'change:views:*:style', (view) ->
      @dataEditor.hide()
      @setBody()
      @body.setElement @$el.find '#view-body'
      @render()

    if changeStyle then @setBody()
    if @body then @body.setView view

    @dataEditor.setView view, data
    @stylePicker.setView view
    @filters.setView view
    @changes.setView view

  rendered: false
  render: ->
    if !@rendered
      @$el.append App.Template.View()

      @changes.setElement @$el.find '#view-changes'
      @body.setElement @$el.find '#view-body'
      @dataEditor.setElement @$el.find '#data-editor'
      @stylePicker.setElement @$el.find '#style-picker'
      @filters.setElement @$el.find '#filters'

      @rendered = true
    @_render()

  _render: ->
    @changes.render()
    if @body.setPage then @body.setPage @page
    @body.render()
    @dataEditor.render()
    @stylePicker.render()
    @filters.render()
  