define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/views/DialogBaseView'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'jst/outcomes/outcomePopover'
], (I18n, $, _, DialogBaseView, OutcomeLineGraphView, template) ->
  class OutcomeResultsDialogView extends DialogBaseView
    @optionProperty 'model'
    $target: null
    template: template

    initialize: ->
      super
      @outcomeLineGraphView = new OutcomeLineGraphView({
        model: @model
      })

    afterRender: ->
      @outcomeLineGraphView.setElement(@$("div.line-graph"))
      @outcomeLineGraphView.render()

    dialogOptions: ->
      containerId: "outcome_results_dialog"
      close: @onClose
      buttons: []
      width: 460

    show: (e) ->
      return unless (e.type == "click" || @_getKey(e.keyCode))
      @$target = $(e.target)
      e.preventDefault()
      @$el.dialog('option', 'title', @model.get('title'))
      super
      @render()

    onClose: =>
      @$target.focus()
      delete @$target

    toJSON: ->
      json = super
      _.extend json,
        dialog: true

    # Private
    _getKey: (keycode) =>
      keys = {
        13 : "enter"
        32 : "spacebar"
      }
      keys[keycode]
