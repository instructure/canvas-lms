define [
  'Backbone'
  'jst/feature_flags/featureFlag'
], (Backbone, template) ->

  class FeatureFlagView extends Backbone.View

    tagName: 'li'

    className: 'feature-flag'

    template: template

    els:
      '.element_toggler': '$detailToggle'

    events:
      'click button':           'onToggleValue'
      'click .element_toggler': 'onToggleDetails'

    onToggleValue: (e) ->
      @toggleValue($(e.currentTarget))

    onToggleDetails: (e) ->
      @toggleDetailsArrow()

    toggleDetailsArrow: ->
      @$detailToggle.toggleClass('icon-mini-arrow-right')
      @$detailToggle.toggleClass('icon-mini-arrow-down')

    shouldDelete: (action) ->
      ENV.ACCOUNT?.site_admin && @model.get('hidden') && action == 'off'

    toggleValue: ($target) ->
      $target.siblings().removeClass('active').attr('aria-checked', false)
      $target.addClass('active').attr('aria-checked', true)
      action = $target.data('action')
      if @shouldDelete(action) then @deleteFlag() else @updateFlag(action)

    deleteFlag: ->
      @model.destroy(silent: true)

    updateFlag: (action) ->
      @model.save(state: action)
