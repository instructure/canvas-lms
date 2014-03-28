define [
  './application_adapter'
], (ApplicationAdapter) ->

  JSONAPIAdapter = ApplicationAdapter.extend

    # private
    #
    # This method will be used later when we need to override createRecord.
    # Serializes the data such that a single quiz or multiple quizzes will
    # be serialized as { "quizzes": [ quiz ] }
    _jsonapiSerialize: (data, store, type, record) ->
      {typeKey} = type
      path = @pathForType typeKey

      data[path] = [
        store.serializerFor(typeKey).serialize(record)
      ]

    # @override
    updateRecord: (store, type, record) ->
      {typeKey} = type
      data = {}
      id = record.get 'id'

      @_jsonapiSerialize data, store, type, record

      @ajax @buildURL(typeKey, id), 'PUT', data: data
