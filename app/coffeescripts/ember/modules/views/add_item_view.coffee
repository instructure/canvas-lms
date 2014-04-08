define ['ember'], (Ember) ->

  AddItemView = Ember.View.extend

    focus: (->
      return unless @get('controller.returnFocus')
      # TODO focus the right thing after adding, right now it works incidentally
      Ember.run.scheduleOnce 'afterRender', this, ->
        @$(':tabbable').first()[0].focus()
        @set('controller.returnFocus', no)
    ).observes('controller.returnFocus')

    escapeOnKeydown: ((event) ->
      return if event.keyCode isnt 27 or @get('controller.editing') isnt yes
      @get('controller').send('quitEditing')
      event.stopPropagation()
    ).on('keyDown')

