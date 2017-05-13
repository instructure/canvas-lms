define [
  'compiled/views/LockButtonView'
], (LockButtonView, _) ->

  class LockIconView extends LockButtonView
    lockClass: 'lock-icon-lock'
    lockedClass: 'lock-icon-locked'
    unlockClass: 'lock-icon-unlock'

    tagName: 'span'
    className: 'lock-icon'

    # These values allow the default text to be overridden if necessary
    @optionProperty 'lockText'
    @optionProperty 'unlockText'

    initialize: ->
      super
      @events = Object.assign({}, LockButtonView.prototype.events, @events)

    events: {'keyclick' : 'click'}
