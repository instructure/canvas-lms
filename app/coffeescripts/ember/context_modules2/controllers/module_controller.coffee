define [
  'ember'
], (Ember) ->
  Ember.ObjectController.extend
    editable: true
    actions:
      loadNextPage: ->
        this.get('model').loadNextPage()
    empty: (->
      this.get('items.length') is 0
    ).property('items')