define [
  'jquery'
  'Backbone'
  'compiled/views/feature_flags/FeatureFlagDialog'
  'jst/feature_flags/featureFlag'
], ($, Backbone, FeatureFlagDialog, template) ->

  class FeatureFlagView extends Backbone.View

    tagName: 'li'

    className: 'feature-flag'

    template: template

    els:
      '.element_toggler i': '$detailToggle'

    events:
      'change .ff_button': 'onClickThreeState'
      'change .ff_toggle': 'onClickToggle'
      'click .element_toggler': 'onToggleDetails'
      'keyclick .element_toggler': 'onToggleDetails'

    afterRender: ->
      @$('.ui-buttonset').buttonset()

    onClickThreeState: (e) ->
      $target = $(e.currentTarget)
      action = $target.data('action')
      @applyAction(action)

    onClickToggle: (e) ->
      $target = $(e.currentTarget)
      @applyAction(if $target.is(':checked') then 'on' else 'off')

    onToggleDetails: (e) ->
      @toggleDetailsArrow()

    toggleDetailsArrow: ->
      @$detailToggle.toggleClass('icon-mini-arrow-right')
      @$detailToggle.toggleClass('icon-mini-arrow-down')

    applyAction: (action) ->
      $.when(@canUpdate(action)).then(
        =>
          @model.updateState(action)
        =>
          @render() # undo UI change if user cancels
      )

    canUpdate: (action) ->
      deferred = $.Deferred()
      warning  = @model.warningFor(action)
      return deferred.resolve() if !warning
      view = new FeatureFlagDialog
        deferred: deferred
        message: warning.message
        title: @model.get('display_name')
        hasCancelButton: !warning.locked
      view.render()
      view.show()
      deferred
