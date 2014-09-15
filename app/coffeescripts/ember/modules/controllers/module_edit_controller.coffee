define ['ember', 'timezone'], (Ember, tz) ->

  ModuleEditController = Ember.ObjectController.extend

    # on init because it needs to go before clearUnlockAtOnUncheck
    setUnlockAtChecked: (->
      @set('unlockAtChecked', yes) if @get('unlock_at')
    ).observes('unlock_at').on('init')

    ##
    # When users uncheck "unlock at", we remove "unlock_at" from the model, but
    # we also save the old value so we can put it back if they check the box
    # again, especially useful for accidental clicks on the checkbox

    clearUnlockAtOnUncheck: (->
      if !@get('unlockAtChecked')
        @set('oldUnlockAt', @get('unlock_at'))
        @set('unlock_at', null)
      else
        old = @get('oldUnlockAt')
        @set('unlock_at', old) if old
    ).observes('unlockAtChecked')

