define [
  'ember-data'
], (DS) ->
  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      #make sure we have a quiz_submissions key when there are no
      #quiz_submission in the server data
      payload.quiz_submissions = [] unless payload.quiz_submissions
      @_super(store, type, payload, id, requestType)
