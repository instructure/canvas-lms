define [
  'ember-data'
], (DS) ->

  DS.ActiveModelSerializer.extend

    extractArray: (store, type, payload) ->
      payload['student_quiz_submissions'] = payload['quiz_submissions']
      delete payload['quiz_submissions']
      @_super store, type, payload
