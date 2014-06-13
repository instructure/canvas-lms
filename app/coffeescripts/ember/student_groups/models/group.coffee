define [
  'ember'
  'ember-data'
], (Ember,DS) ->

  attr = DS.attr

  Group = DS.Model.extend

    name: attr()
    join_level: attr()
    users: attr()

  Group.reopenClass

    url: ->
      "/api/v1"

