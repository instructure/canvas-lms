define [
  'underscore'
  'Backbone'
  'compiled/util/natcompare'
], (_, {Model, Collection}, natcompare) ->
  class Group extends Model
    initialize: ->
      @set('outcomes', new Collection([], comparator: natcompare.byGet('title')))

    count: -> @get('outcomes').length

    mastery_count: ->
      @get('outcomes').filter((x) ->
        x.status() == 'mastery'
      ).length

    toJSON: ->
      _.extend(super, count: @count(), mastery_count: @mastery_count())
