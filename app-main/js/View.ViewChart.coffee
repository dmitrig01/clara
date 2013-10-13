App.View.ViewChart = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo Application, 'change:views:*:styleData change:views:*:filters', @render
  setPage: (page) -> # no pager
  events:
    'change select#view-chart-key': -> @view._('styleData:chartKey').set(@$el.find('select#view-chart-key').val())
    'change select#view-chart-type': -> @view._('styleData:chartType').set(@$el.find('select#view-chart-type').val())
  render: ->
    aggregators = @view._('aggregators')
    group = @view.get('group')

    options = {}
    aggregators.each (aggregator) ->
      column = Application._('categories:default:columns')._(aggregator.get('column'))
      options[aggregator.get('id')] = column.get('name') + ': ' + column.type().aggregators[aggregator.get('type')]
    options._count = 'Number of items'

    chartKey = @view.get('styleData:chartKey')

    @view.run 0, (result) =>
      groupColumn = Application._('categories:default:columns')._(@view.get('group').column)
      labels = []
      data = []
      max = 0
      for key, value of result.aggregators
        labels.push groupColumn.type().groupFormat @view.get('group').type, key
        data.push value[chartKey]
        max = Math.max value[chartKey], max

      @$el.empty().append App.Template.ViewChart
        options: options
        chartKey: chartKey
        chartType: @view.get('styleData:chartType')


      type = if @view.get('styleData:chartType') == 'bar' then 'Bar' else 'Line'
      new Chart($('#view-chart-chart')[0].getContext('2d'))[type] { labels: labels, datasets: [ { fillColor: "rgba(151,187,205,0.5)", strokeColor: "rgba(151,187,205,1)", data: data } ] },
        scaleStartValue: Math.ceil(max / 8)
        scaleStepWidth: Math.max Math.ceil(max / 8), 1
        scaleSteps: 8
        scaleOverride: true
        scaleFontFamily: 'Lucida Grande'
        scaleFontColor: '#000'