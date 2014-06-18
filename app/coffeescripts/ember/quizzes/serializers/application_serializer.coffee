define [
  'ember-data'
], (DS) ->

  ApplicationSerializer = DS.ActiveModelSerializer.extend

    # A lot of CanvasAPI responses look like:
    # {
    #   "id": "1",
    #   "attribute": "value"
    # }
    #
    # Turn them into:
    #
    # {
    #   "pluralized_resource_name": [{
    #     "id": "1",
    #     "attribute": "value"
    #   }]
    # }
    extractSingle: (store, type, payload, id, requestType) ->
      obj = {}
      obj[type.typeKey.pluralize()] = payload
      this._super store, type, obj, id, requestType
