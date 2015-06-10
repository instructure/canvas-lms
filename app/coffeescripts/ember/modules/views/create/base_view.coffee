define ['ember'], (Ember) ->

  CreateItemBaseView = Ember.View.extend

    focusOnInsert: (->
      @$(':tabbable').first()[0].focus()
    ).on('didInsertElement')

