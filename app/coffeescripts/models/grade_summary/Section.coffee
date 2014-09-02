define [
  'underscore'
  'Backbone'
  'compiled/util/natcompare'
], (_, {Model, Collection}, natcompare) ->
  class Section extends Model
    initialize: ->
      @set('groups', new Collection([], comparator: natcompare.byGet('title')))
