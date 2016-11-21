define [
  'jst/assignments/TurnitinSettingsDialog'
  'jst/assignments/VeriCiteSettingsDialog'
  'Backbone'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/jquery/fixDialogButtons'
], (turnitinSettingsDialog, vericiteSettingsDialog, { View }, $, _, htmlEscape) ->

  class TurnitinSettingsDialog extends View

    tagName: 'div'

    EXCLUDE_SMALL_MATCHES_OPTIONS = '.js-exclude-small-matches-options'
    EXCLUDE_SMALL_MATCHES = '#exclude_small_matches'
    EXCLUDE_SMALL_MATCHES_TYPE = '[name="exclude_small_matches_type"]'

    constructor: (model, type) ->
      super(model: model)
      @type = type

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
          <input class="span1" id="exclude_small_matches_words_value" name="words" value="#{htmlEscape json.words}" type="text"/>
        """
        percentInput: """
          <input class="span1" id="exclude_small_matches_percent_value" name="percent" value="#{htmlEscape json.percent}" type="text"/>
        """

    renderEl: =>
      if @type == "vericite"
        html = vericiteSettingsDialog(@toJSON())
      else
        html = turnitinSettingsDialog(@toJSON())
      @$el.html(html)
      @$el.dialog({width: 'auto', modal: true}).fixDialogButtons()

    getFormValues: =>
      values = @$el.find('form').toJSON()
      if @$excludeSmallMatches.prop 'checked'
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
