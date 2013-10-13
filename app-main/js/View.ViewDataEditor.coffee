App.View.ViewDataEditor = Backbone.View.extend
  events:
    'submit form': ->
      @data.save @serialize(), { success: -> Application.trigger 'data' }
      @hide()
    'click .data-editor-cancel': -> @hide()
    'click .data-add': ->
      App.route.navigateView { data: 'new' }
      false
    'click .column-edit': (e) ->
      colEditView = new App.View.ColumnEdit
      colEditView.setColumn Application._('categories:default:columns')._($(e.target).attr('id').replace('column-edit-', ''))
      colEditView.render()
      false
    'click .column-delete': (e) ->
      columnId = Application._('categories:default:columns')._($(e.target).attr('id').replace('column-edit-', '')).get('id')

      Application._('views').each (view) -> view.get('styleData:fields').remove (col) -> col.key == columnId

      column = Application._('categories:default:columns').remove($(e.target).attr('id').replace('column-edit-', ''))
      false
 
  setView: (view, dataId) ->
    @view = view
    if dataId == 'new'
      @data = new App.Model.Data
      @values = {}
      @renderAction = 'show'
    else if dataId
      if !@data || @data.id != dataId
        @data = new App.Model.Data { id: dataId }
        @renderAction = 'show'
      else
        @renderAction = 'reshow'
    else
      @data = null
      @renderAction = 'hide'
    @listenTo Application, 'change:categories:default:columns', => @renderAction = 'reshow'; @render()

  serialize: ->
    if !@data then return
    values = {}
    @$el.find('.data-editor-row').each ->
      if $(this).attr('id')
        key = $(this).attr('id').replace('data-editor-row-', '')
        value = Application._('categories:default:columns')._(key).type().widget.fromElement $(this).find('.data-editor-row-widget-wrapper')
        values[key] = value
    @values = values

  render: -> switch @renderAction
    when 'reshow'
      @serialize()
      @_render()
    when 'show'
      if @data.id
        @data.fetch
          success: =>
            @values = {}
            Application._('categories:default:columns').each (column) => @values[column.get('id')] = column.type().widget.toValue @data.get(column.get('id'))
            @_render()

      else @_render()

    when 'hide'
      @$el.empty().append('<a href="#" class="data-add">+ Add new entry</a>')

  _render: ->
    @$el.empty().append App.Template.ViewDataEditor
      columns: Application._('categories:default:columns')
      values: @values ? {}

  hide: -> App.route.navigateView { data: '' }; false
