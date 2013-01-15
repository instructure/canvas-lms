define [
  'jst/assignments/TurnitinSettingsDialog'
  'Backbone'
  'jquery'
  'underscore'
], (turnitinSettingsDialog, { View }, $, _) ->

  class TurnitinSettingsDialog extends View

    EXCLUDE_SMALL_MATCHES_OPTIONS = '.js-exclude-small-matches-options'
    EXCLUDE_SMALL_MATCHES = '[name="exclude_small_matches"]'
    EXCLUDE_SMALL_MATCHES_TYPE = '[name="exclude_small_matches_type"]'

    initialize: -> @settings = @model

    _findElements: =>
      @$excludeSmallMatchesOptions = @$el.find EXCLUDE_SMALL_MATCHES_OPTIONS
      @$excludeSmallMatches = @$el.find EXCLUDE_SMALL_MATCHES
      @$excludeSmallMatchesType = @$el.find EXCLUDE_SMALL_MATCHES_TYPE

    tagName: 'div'

    events: do ->
      events = {}
      events.submit = 'handleSubmit'
      events[ "change #{EXCLUDE_SMALL_MATCHES}" ] = 'toggleExcludeOptions'
      events

    toggleExcludeOptions: =>
      if @$excludeSmallMatches.prop 'checked'
        @$excludeSmallMatchesOptions.show()
      else
        @$excludeSmallMatchesOptions.hide()

    render: =>
      values = _.extend @settings.toView(),
        wordsInput: """
          <input id="exclude_small_matches_words_value" name="words" value="#{@settings.words()}" type="text"/>
        """
        percentInput: """
          <input id="exclude_small_matches_percent_value" name="percent" value="#{@settings.percent()}" type="text"/>
        """
      @$el.html(turnitinSettingsDialog(values))
      @$el.dialog
        width: 'auto'
        modal: true
      .fixDialogButtons()
      @_findElements()
      this

    getFormValues: =>
      values = @$el.find('form').toJSON()
      values.exclude_small_matches_type = @$excludeSmallMatchesType.val()
      if values.exclude_small_matches_type is 'words'
        values.exclude_small_matches_value = values.words
      else
        values.exclude_small_matches_value = values.percent
      values

    handleSubmit: (ev) =>
      ev.preventDefault()
      ev.stopPropagation()
      @$el.dialog 'close'
      @trigger 'settings:change', @getFormValues()
