App.View.Import = Backbone.View.extend
  render: ->
    @stage ?= 'enter'
    @$el.empty().append App.Template.Import
      stage: @stage
    view = switch @stage
      when 'enter' then App.View.Enter
      when 'verify' then App.View.Verify
      when 'process' then App.View.Process
    (new view { el: @$el.find('#import-body') }).render()