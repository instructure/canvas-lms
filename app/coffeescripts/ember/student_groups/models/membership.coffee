define [
  'ember'
  'ember-data'
], (Ember, DS) ->
  Membership = DS.Model.extend
    user_id: DS.attr('number')
    group_id: DS.attr('number')
