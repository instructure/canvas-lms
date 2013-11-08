define [
  'jst/assignments/TurnitinSettingsDialog'
  'Backbone'
  'jquery'
  'underscore'
  'compiled/jquery/fixDialogButtons'
], (turnitinSettingsDialog, { View }, $, _) ->

  class TurnitinSettingsDialog extends View

    tagName: 'div'

    EXCLUDE_SMALL_MATCHES_OPTIONS = '.js-exclude-small-matches-options'
    EXCLUDE_SMALL_MATCHES = '#exclude_small_matches'
    EXCLUDE_SMALL_MATCHES_TYPE = '[name="exclude_small_matches_type"]'

    events: do ->
      events = {}
      events.submit = 'handleSubmit'
      events["change #{EXCLUDE_SMALL_MATCHES}"] = 'toggleExcludeOptions'
      events

    els: do ->
      els = {}
      els["#{EXCLUDE_SMALL_MATCHES_OPTIONS}"] = '$excludeSmallMatchesOptions'
      els["#{EXCLUDE_SMALL_MATCHES}"] = '$excludeSmallMatches'
      els["#{EXCLUDE_SMALL_MATCHES_TYPE}"] = '$excludeSmallMatchesType'
      els

    toggleExcludeOptions: =>
      if @$excludeSmallMatches.prop 'checked'
        @$excludeSmallMatchesOptions.show()
      else
        @$excludeSmallMatchesOptions.hide()

    toJSON: =>
      json = super
      _.extend json,
        wordsInput: """
          <input class="span1" id="exclude_small_matches_words_value" name="words" value="#{json.words}" type="text"/>
        """
        percentInput: """
          <input class="span1" id="exclude_small_matches_percent_value" name="percent" value="#{json.percent}" type="text"/>
        """

    renderEl: =>
      @$el.html(turnitinSettingsDialog(@toJSON()))
      @$el.dialog({width: 'auto', modal: true}).fixDialogButtons()

    getFormValues: =>
      values = @$el.find('form').toJSON()
      if @$excludeSmallMatches.prop 'checked'
        values.exclude_small_matches_type = @$excludeSmallMatchesType.val()
        if values.exclude_small_matches_type is 'words'
          values.exclude_small_matches_value = values.words
        else
          values.exclude_small_matches_value = values.percent
      else
        values.exclude_small_matches_type = null
        values.exclude_small_matches_value = null
      values

    handleSubmit: (ev) =>
      ev.preventDefault()
      ev.stopPropagation()
      @$el.dialog 'close'
      @trigger 'settings:change', @getFormValues()
