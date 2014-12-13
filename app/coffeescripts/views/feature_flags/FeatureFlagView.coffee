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
      'click button':           'onToggleValue'
      'click .element_toggler': 'onToggleDetails'
      'keyclick .element_toggler': 'onToggleDetails'

    onToggleValue: (e) ->
      @toggleValue($(e.currentTarget))

    onToggleDetails: (e) ->
      @toggleDetailsArrow()

    toggleDetailsArrow: ->
      @$detailToggle.toggleClass('icon-mini-arrow-right')
      @$detailToggle.toggleClass('icon-mini-arrow-down')

    shouldDelete: (action) ->
      @model.get('hidden') && action == 'off'

    toggleValue: ($target) ->
      action = $target.data('action')
      $.when(@canUpdate(action)).then =>
        $target.siblings().removeClass('active').attr('aria-checked', false)
        $target.addClass('active').attr('aria-checked', true)
        if @shouldDelete(action) then @deleteFlag() else @updateFlag(action)

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

    deleteFlag: ->
      @model.destroy(silent: true)

    updateFlag: (action) ->
      @model.save(state: action).then(@model.updateTransitions)
