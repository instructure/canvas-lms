define [
  'ember'
  'ember-data'
  'ic-ajax'
], (Ember, DS,ajax) ->
  MembershipAdapter = DS.RESTAdapter.extend
    namespace: 'api/v1'

    urlFor: (record) ->
      "/#{@namespace}/groups/#{record.get('group_id')}/memberships"


    createRecord: (store, type, record) ->
      @ajax(@urlFor(record), "POST", { data: { user_id: record.get('user_id') }})

