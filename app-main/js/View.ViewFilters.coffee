App.View.ViewFilters = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo Application, 'change:views:*:filters', @render
  events:
    'change .filter-wrapper input, .filter-wrapper select': (e) ->
      element = $(e.target).parents('.filter-wrapper')
      filter = @view._('filters')._ parseInt element.attr('id').replace('filter-wrapper-', '')
      key = filter.get('key')

      console.log key
      filterInfo = Application._('categories:default:columns')._(key).type().filter.serialize element

      filterInfo.key = key
      filter.set(filterInfo)

    'click .filter-remove': (e) ->
      @view._('filters').remove parseInt($(e.target).attr('id').replace('filter-remove-', ''))
      return false

    'change .add-new-filter': (e) ->
      if column = $(e.target).val()
        @view._('filters').push { key: column }
        $('#filter-' + (@view._('filters').size() - 1)).focus()

  render: ->
    filters = []
    @view._('filters').each (filter, index) =>
      column = Application._('categories:default:columns')._(filter.get('key'))
      filters.push
        filter: filter
        index: index
        column: column

    @$el.empty().append App.Template.ViewFilters
      filters: filters
      application: Application
      columns: Application._('categories:default:columns')