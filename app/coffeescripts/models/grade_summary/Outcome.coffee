define [
  'underscore'
  'Backbone'
], (_, {Model, Collection}) ->
  class Outcome extends Model
    status: ->
      score = @get('score')
      mastery = @get('mastery_points')
      if score >= mastery
        'mastery'
      else if score >= mastery / 2
        'near'
      else
        'remedial'

    toJSON: ->
      _.extend(super, status: @status())
