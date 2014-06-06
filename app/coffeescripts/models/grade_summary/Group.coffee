define [
  'underscore'
  'Backbone'
  'compiled/util/natcompare'
], (_, {Model, Collection}, natcompare) ->
  class Group extends Model
    initialize: ->
      @set('outcomes', new Collection([], comparator: natcompare.byGet('title')))

    count: -> @get('outcomes').length


    statusCount: (status) ->
      @get('outcomes').filter((x) ->
        x.status() == status
      ).length

    mastery_count: ->
      @statusCount('mastery')

    remedialCount: ->
      @statusCount('remedial')

    undefinedCount: ->
      @statusCount('undefined')

    status: ->
      if @remedialCount() > 0
        "remedial"
      else
        if @mastery_count() == @count()
          "mastery"
        else if @undefinedCount() == @count()
          "undefined"
        else
          "near"

    started: ->
      true

    toJSON: ->
      _.extend super,
        count: @count()
        mastery_count: @mastery_count()
        started: @started()
        status: @status()
