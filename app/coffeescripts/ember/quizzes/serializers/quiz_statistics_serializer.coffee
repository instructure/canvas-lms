define [ 'ember-data', 'underscore' ], (DS, _) ->
  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      payload.question_statistics = payload.quiz_statistics[0].question_statistics

      @_super(store, type, payload, id, requestType)