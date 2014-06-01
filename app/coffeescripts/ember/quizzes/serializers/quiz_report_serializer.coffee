define [ 'ember-data' ], (DS) ->
  DS.ActiveModelSerializer.extend
    extractSingle: (store, type, payload, id, requestType) ->
      @_super store, type, { quiz_reports: [ payload ] }, id, requestType