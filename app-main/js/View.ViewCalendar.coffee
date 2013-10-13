App.View.ViewCalendar = Backbone.View.extend
  events:
    'click .view-calendar-navigate': (e) ->
      page = switch $(e.target).attr('id').replace('view-calendar-navigate-', '')
        when 'previous-year'  then '' + @month + (@year - 1)
        when 'previous-month' then '' + (if @month - 1 < 0 then 11 else @month - 1) + (if @month - 1 < 0 then @year - 1 else @year)
        when 'next-month'     then '' + ((@month + 1) % 12) + (if @month + 1 > 11 then @year + 1 else @year)
        when 'next-year'      then '' + @month + (@year + 1)
      App.route.navigateView { page }
      false

  setView: (view) ->
    @view = view
    @listenTo @view, 'change:filters', @render
  setPage: (page) ->
    page = parseInt page ? 0
    if page
      @year = page % 10000
      @month = (page - @year)/10000
    else
      @year = new Date().getFullYear()
      @month = new Date().getMonth()


  render: ->
    @view.run @year + (@month * 10000), (result) =>
      dateColumn = Application._('categories:default:columns').findOne((column) -> column.get('type') == 'date')
      dateColumnId = dateColumn.get('id')
      items = {}
      for data in result.data
        date = (new Date(data[dateColumnId].timestamp * 1000)).getDate()
        items[date] ?= []
        items[date].push App.Template.Data
          data: new App.Model.Data data
          columns: Application._('categories:default:columns')
      @draw items

  draw: (items) ->
    firstDay = new Date(@year, @month, 1).getDay()
    days = @_days(@month, @year)
    @$el.empty().append App.Template.ViewCalendar
      monthName: App.monthNames[@month]
      days: days
      firstDay: firstDay
      year: @year
      month: @month
      items: items
  _days: (month, year) ->
    leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    days = [
      31
      (if leap then 29 else 28)
      31
      30
      31
      30
      31
      31
      30
      31
      30
      31
    ]
    days[month]