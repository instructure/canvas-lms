define [
  'underscore'
  'Backbone'
], (_, {Model, Collection}) ->
  class Outcome extends Model
    status: ->
      if @scoreDefined()
        score = @get('score')
        mastery = @get('mastery_points')
        if score >= mastery
          'mastery'
        else if score >= mastery / 2
          'near'
        else
          'remedial'
      else
        'undefined'

    scoreDefined: ->
      _.isNumber(@get('score'))

    percentProgress: ->
      if @scoreDefined()
        @get('score')/@get('points_possible') * 100
      else
        0

    masteryPercent: ->
      @get('mastery_points')/@get('points_possible') * 100

    toJSON: ->
      _.extend super,
        status: @status()
        scoreDefined: @scoreDefined()
        percentProgress: @percentProgress()
        masteryPercent: @masteryPercent()
