App.View.ViewTable = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo Application, 'change:categories:default:columns change:views:*:styleData change:views:*:filters change:views:*:group change:views:*:aggregators change:views:*:sort save', @render
    @listenTo Application, 'data', @render
  setPage: (page) ->
    @page = parseInt page ? 0
  events:
    'change .table-view-add': (e) ->
      if column = $(e.target).val() then @view._('styleData:fields').push { key: column }
    'click .table-view-remove': (e) ->
      @view._('styleData:fields').remove(parseInt $(e.target).attr('id').replace('table-view-remove-', ''))
      false
    'click .table-view-order': (e) ->
      [direction, column] = $(e.target).attr('id').replace('table-view-order-', '').split('-')
      @view._('sort').set { column, direction }
      false
    'click .data-row': (e) ->
      App.route.navigateView { data: $(e.target).parents('tr').attr('id').replace('data-row-', '') }

    'click .table-view-agg': (e) ->
      Application.transaction =>
        aggregator = @view._('styleData:fields')._($(e.target).parents('th').index())._('aggregator')
        if agg = aggregator.get()
          @view._('aggregators').remove(agg)
        @view._('styleData:fields')._($(e.target).parents('th').index()).remove('aggregator')
      false

    'click .table-view-removegroup': ->
      @view._('group').set {}
      false

    'click .table-view-group': (e) ->
      @groupColumn = $(e.target).attr('id').replace('table-view-group-', '')
      @groupIndex = $(e.target).parents('th').index()
      
    'click .dropdown a': (e) ->
      Application.transaction =>
        [dropdownType, type] = $(e.target).attr('id').replace('dropdown-', '').split('-')
        if dropdownType == 'group'
          @view._('group').set({ column: @groupColumn, type })
        else
          aggregator = @view._('styleData:fields')._(@groupIndex)._('aggregator')
          if agg = aggregator.get('id')
            @view._('aggregators').remove(agg)
       
          aggregator.set @view._('aggregators').push { column: @groupColumn, type }

      $.fn.dropdown('hide')
      false
    'click .pager-next': ->
      App.route.navigateView { page: (@page + 1) }
    'click .pager-prev': ->
      App.route.navigateView { page: (@page - 1) }

  render: ->
    @view.run @page, (result) =>
      if true#result.data.length == 0 && result.count > 0
      #  # We managed to go beyond the last page, probably because a filter was
      #  # imposed; go to the last page.
      #  App.route.navigateView { page: (Math.ceil(result.count / App.pageSize) - 1) }
      #else
        columns = Application._('categories:default:columns')

        aggregators = false
        headers = _.map @view.get('styleData:fields'), (field) ->
          aggregators ||= field.aggregator
          return {
            key: field.key
            aggregator: field.aggregator
            column: columns._(field.key)
            type: columns._(field.key).type()
          }

        vars =
          application: Application
          data: result.data
          headers: headers
          page: @page + 1
          pages: Math.ceil(result.count / App.pageSize)
          view: @view
          columns: columns
          aggregators: ''
          aggregatorTotals: ''

        if groupColumn = @view.get('group:column')
          vars.group = (name) => columns._(groupColumn).type().groupFormat @view.get('group:type'), name

        if aggregators
          vars.aggregators = result.aggregators
          vars.aggregatorTotals = result.aggregatorTotals

        @$el.empty().append App.Template.ViewTable vars