define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'timezone'
  'compiled/views/grade_summary/ProgressBarView'
  'compiled/util/Popover'
  'jst/grade_summary/outcome'
  'jst/grade_summary/mastery_hover'
], (I18n, _, Backbone, tz, ProgressBarView, Popover, template, mastery_hover) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template
    mastery_hover: mastery_hover

    TIMEOUT_LENGTH: 50

    events:
      'keydown .alignment-info i' : 'togglePopover'
      'mouseenter .alignment-info i': 'mouseenter'
      'mouseleave .alignment-info i': 'mouseleave'

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    toJSON: ->
      json = super
      _.extend json,
        statusTooltip: @statusTooltip()
        progress: @progress

    createPopover: (e) ->
      methodContent = @getMethodContent()
      attributes = {
        scoreDefined: @model.scoreDefined()
        score: @model.get('score')
        latestTitle: @model.get('resultTitle') || I18n.t("N/A")
        masteryPoints: @model.get('mastery_points')
        masteryLevel: @model.status()
        method: methodContent.method
        exampleText: methodContent.exampleText
        exScores: methodContent.exScores
        exResult: methodContent.exResult
        submissionTime: @getSubmissionTime(@model.get('submissionTime'))
      }
      popover = new Popover(e, @mastery_hover(attributes), verticalSide: 'bottom', manualOffset: 14)
      popover.el.on('mouseenter', @mouseenter)
      popover.el.on('mouseleave', @mouseleave)
      popover.show(e)
      popover

    statusTooltip: ->
      switch @model.status()
        when 'undefined' then I18n.t 'undefined', 'Unstarted'
        when 'remedial' then I18n.t 'remedial', 'Remedial'
        when 'near' then I18n.t 'near', 'Near mastery'
        when 'mastery' then I18n.t 'mastery', 'Mastery'

    getSubmissionTime: (time) ->
      if time
        @model.get('submissionTime')

    getMethodContent: ->
      #highest for outcomes that pre-date change without a method set
      #so they keep their original behavior
      currentMethod = @model.get('calculation_method') || 'highest'
      methodInt = @model.get('calculation_int')
      switch currentMethod
        when "decaying_average" then {
          method: I18n.t("%{recentInt}/%{remainderInt} Decaying Average", {recentInt: methodInt, remainderInt: 100 - methodInt}),
          exampleText: I18n.t("Most recent score counts as 75% of mastery weight, average of all other scores count as 25% of weight."),
          exScores: "1, 3, 2, 4, 5, 3, 6",
          exResult: "5.25"
        }
        when 'n_mastery' then {
          method: I18n.t("Achieve mastery %{count} times", {count: methodInt}),
          exampleText: I18n.t("Must achieve mastery at least 2 times. Scores above mastery will be averaged to calculate final score."),
          exScores: "1, 3, 2, 4, 5, 3, 6",
          exResult: "5.5"
        }
        when 'latest' then {
          method: I18n.t("Latest Score"),
          exampleText: I18n.t("Mastery score reflects the most recent graded assigment or quiz."),
          exScores: "2, 4, 5, 3",
          exResult: "3"
        }
        when 'highest' then {
          method: I18n.t("Highest Score"),
          exampleText: I18n.t("Mastery scrore reflects the highest score of a graded assignment or quiz."),
          exScores: "5, 3, 4, 2",
          exResult: "5"
        }

    togglePopover: (e) =>
      keyPressed = @getKey(e.keyCode)
      if keyPressed == "spacebar"
        @openPopover(e)
      else if keyPressed == "escape"
        @closePopover(e)

    openPopover: (e) =>
      e.preventDefault()
      if @popover
        @popover.hide()
        delete @popover
      @popover = @createPopover(e)

    closePopover: (e) =>
      return unless @popover
      e.preventDefault()
      @popover.hide()
      delete @popover

    mouseenter: (e) =>
      @popover = @createPopover(e) unless @popover
      @inside  = true

    mouseleave: (e) =>
      @inside  = false
      setTimeout =>
        return if @inside || !@popover
        @popover.hide()
        delete @popover
      , @TIMEOUT_LENGTH

    getKey: (keycode) =>
      keys = {
        32 : "spacebar"
        27 : "escape"
      }
      keys[keycode]
