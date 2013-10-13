App.View.ColumnEdit = Backbone.View.extend
  setColumn: (column) -> @column = column ? {}
  events:
    'submit form': ->
      Application.transaction (delayed) =>
        @column._('name').set(@$el.find('#name').val())

        if @$el.find('#type').val() != @column.get('type')
          clone = OriginalApplication.clone()
          clone._('categories:default:columns')._(@column.get('id'))._('type').set(@$el.find('#type').val())

          delayed()
          clone.save =>
            delayed()
            @column._('type').set(@$el.find('#type').val())

      $.modal.close()
      false
  render: ->
    $('body').append App.Template.ColumnEdit { column: @column }
    @setElement '#column-edit'
    @$el.one('modal:close', => @el.remove()).modal()