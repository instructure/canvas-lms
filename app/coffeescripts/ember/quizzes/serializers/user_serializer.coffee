define [
  'ember-data'
], (DS) ->

  UserSerializer = DS.ActiveModelSerializer.extend
    extractArray: (store, primaryType, payload) ->
      payload['users']?.forEach (user) ->
        user.quiz_submission_id = user['links']['quiz_submission']
        delete user.links.quiz_submission
      @_super store, primaryType, payload
