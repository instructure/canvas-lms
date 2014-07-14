define [
  'ember'
  'ember-data'
  'ic-ajax'
], (Ember, DS,ajax) ->
  GroupAdapter = DS.RESTAdapter.extend
    namespace: 'api/v1'

    urlFor: (record) ->
      if record.get('course_id')
        "/courses/#{record.get('course_id')}/groups"
      else
        "/#{@namespace}/groups"


    createRecord: (store, type, record) ->
      url = @urlFor(record)
      delete record.course_id
      invites = record.invites
      delete record.invites
      @ajax(url, "POST", { data: {group: record, invitees: invites }})

