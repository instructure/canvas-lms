define [
  'i18n!gradebook2'
  'Backbone'
  'compiled/util/Popover'
  'jst/gradebook2/outcome_popover'
], (I18n, {View}, Popover, popover_template) ->

  class OutcomeColumnView extends View

    popover_template: popover_template

    events:
      click: 'click'

    click: (e) ->
      return if $(e.target).is('.slick-resizable-handle')
      @popover = new Popover(e, @popover_template(@attributes))
