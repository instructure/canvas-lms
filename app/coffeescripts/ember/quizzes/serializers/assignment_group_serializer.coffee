define [
  'ember-data'
], (DS) ->

  DS.ActiveModelSerializer.extend
    extractSingle: (store, type, payload) ->
      @_super(store, type, assignment_group: payload)
