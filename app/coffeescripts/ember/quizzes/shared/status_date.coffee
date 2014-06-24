define [
  'ember',
  'i18n!status_dates',
], (Ember, I18n) ->

  AVAILABLE_STATUS_LABELS = {
    available: I18n.t('available', 'Available'),
    availableUntil: I18n.t('available_until', 'Available until'),
    pending: I18n.t('pending', 'Not available until'),
    closed: I18n.t('closed', 'Closed'),
    none: ''
  }

  Ember.Object.extend

    now: new Date()

    setupDate: ( ->
      setInterval =>
        Ember.run.next =>
          @set 'now', new Date()
      , 1000
    ).on('init')

    availableStatus: ( ->
      lockPassed = @get('lockAt') && (new Date(@get('lockAt')) < @get('now'))
      lockNotPassed = @get('lockAt') && (new Date(@get('lockAt')) > @get('now'))
      unlockPassed = @get('unlockAt') && (new Date(@get('unlockAt')) < @get('now'))
      if lockPassed
        'closed'
      else if @get('unlockAt') && (new Date(@get('unlockAt')) > @get('now'))
        'pending'
      else if (!@get('unlockAt') || unlockPassed) && lockNotPassed
        'availableUntil'
      else
        'none'
    ).property('unlockAt', 'lockAt', 'now')

    availableLabel: ( ->
      AVAILABLE_STATUS_LABELS[@get('availableStatus')]
    ).property('availableStatus')

    availableMultiLabel: ( ->
      lb = @get('availableLabel')
      if lb == AVAILABLE_STATUS_LABELS['none']
        lb = AVAILABLE_STATUS_LABELS['available']
      else if lb == AVAILABLE_STATUS_LABELS['pending']
        lb = I18n.t('not_available', 'Available on')
      lb
    ).property('availableStatus')

    availableDate: ( ->
      if @get('availableStatus') == 'availableUntil'
        @get('lockAt')
      else if @get('availableStatus') == 'pending'
        @get('unlockAt')
      else
        ''
    ).property('availableStatus')

    dueLabel: ( ->
      if @get('dueAt')
        I18n.t('due', 'Due')
    ).property('dueAt')

    dueDate: Em.computed.alias 'dueAt'
