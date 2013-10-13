App.View.ViewStylePicker = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo Application, 'change:views:*:group change:views:*:aggregators', @render
  events:
    'click .view-style:not(.view-style-disabled) a': (e) ->
      oldStyle = @view.get('style')
      newStyle = $(e.target).parents('.view-style').attr('id').replace('view-style-', '')
      if oldStyle != newStyle
        App.route.navigateView { page: 0 }, false
        @view._('style').set(newStyle)
      
      false
    'click .view-style-disabled a': (e) -> false
  render: ->
    @$el.empty().append App.Template.ViewStylePicker
      style: @view.get('style')
      chartStyle: !!@view._('group').size()
      mapStyle: !!(Application._('categories:default:columns').findOne((column) -> column.get('type') == 'location'))
      calendarStyle: !!(Application._('categories:default:columns').findOne((column) -> column.get('type') == 'date'))