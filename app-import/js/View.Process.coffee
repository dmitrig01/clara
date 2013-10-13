App.View.Process = Backbone.View.extend
  render: ->
    if !@currentSteps?
      @$el.empty().append App.Template.Process()
      @currentSteps = 0
      @run()
    else
      @$el.find('.progress-inner').css('width', '' + Math.floor(@currentSteps / @totalSteps * 100) + '%')
  run: ->
    @totalSteps = (App.data.match(/\n/g)||[]).length + 1
    columns = []
    for header, i in App.importInfo.headers
      columns.push Application._('categories:default:columns').push({ name: header, type: App.importInfo.types[i] })
    Application._('views').first()._('styleData:fields').push { key: Application._('categories:default:columns').first().get('id') }

    Application.isNew = true
    Application.save =>
      @currentSteps++
      @render()
      lines = App.data.split /\n/
      if App.importInfo.firstRowHeaders then lines.shift()

      callbacks = lines.length
      callback = =>
        @currentSteps++
        @render()
        callbacks--
        if callbacks == 0 then window.location.href = '/a/' + Application.get('id')
      for line in lines
        parts = line.split /\t/
        datum = new App.Model.Data
        for part, i in parts
          datum.set columns[i], part
        datum.save {}, { success: -> callback() }

