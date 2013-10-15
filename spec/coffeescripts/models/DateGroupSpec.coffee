define [
  'Backbone'
  'compiled/models/DateGroup'
], (Backbone, DateGroup) ->

  module 'DateGroup',
    setup: ->

  test 'default title is set', ->
    dueAt = new Date("2013-08-20 11:13:00")
    model = new DateGroup due_at: dueAt, title: "Summer session"
    equal model.get("title"), 'Summer session'

    model = new DateGroup due_at: dueAt
    equal model.get("title"), 'Everyone else'
