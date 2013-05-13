define [
  'compiled/views/InputView'
], (InputView) ->

  class SelectView extends InputView

    tagName: 'select'

    className: 'select-view'

    events:
      'change': 'updateModel'

