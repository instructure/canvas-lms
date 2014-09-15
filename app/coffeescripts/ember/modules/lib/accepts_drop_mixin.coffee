define [
  'ember'
], (Ember) ->

  Ember.Mixin.create

    accepts: []

    validateDragEvent: (event) ->
      accepts = @get('accepts')
      transfer = event.dataTransfer.types
      for type in accepts
        if transfer.contains(type)
          @set('accept-type', type)
          return true
      false

    resetAcceptType: (->
      @set('accept-type', null)
    ).on('dragLeave'),

    acceptDrop: ->
      type = @get('accept-type')
      @["accept:#{type}"](event, event.dataTransfer.getData(type))
      @set('accept-type', null)

