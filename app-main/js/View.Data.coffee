App.View.Data = Backbone.View.extend
  setData: (data) -> @data = data
  render: ->
    @$el.empty().append App.Template.Data
      data: @data
      columns: Application._('categories:default:columns')