define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/CalculationMethodContent'
], (I18n, _, {Model, Collection}, CalculationMethodContent) ->

  class Outcome extends Model
    defaults:
      calculation_method: "highest"

    initialize: ->
      super
      @set 'friendly_name', @get('display_name') || @get('title')
      @set 'hover_name', (@get('title') if @get('display_name'))

    status: ->
      if @scoreDefined()
        score = @get('score')
        mastery = @get('mastery_points')
        if score >= mastery + (mastery / 2)
          'exceeds'
        else if score >= mastery
          'mastery'
        else if score >= mastery / 2
          'near'
        else
          'remedial'
      else
        'undefined'

    statusTooltip: ->
      {
        'undefined': I18n.t('Unstarted')
        'remedial': I18n.t('Well Below Mastery')
        'near': I18n.t('Near Mastery')
        'mastery': I18n.t('Meets Mastery')
        'exceeds': I18n.t('Exceeds Mastery')
      }[@status()]

    roundedScore: ->
      score = @get('score')
      if _.isNumber(score)
        Math.round(score * 100.0) / 100.0
      else
        null

    scoreDefined: ->
      _.isNumber(@get('score'))

    percentProgress: ->
      if @scoreDefined()
        @get('score')/@get('points_possible') * 100
      else
        0

    masteryPercent: ->
      @get('mastery_points')/@get('points_possible') * 100

    present: ->
      _.extend({}, @toJSON(), new CalculationMethodContent(@).present())

    toJSON: ->
      _.extend super,
        status: @status()
        statusTooltip: @statusTooltip()
        roundedScore: @roundedScore()
        scoreDefined: @scoreDefined()
        percentProgress: @percentProgress()
        masteryPercent: @masteryPercent()
