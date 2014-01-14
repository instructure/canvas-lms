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

    datesFor: ( ->
      if @get('base')
        I18n.t('everyone_else', 'Everyone else')
      else
        @get('title')
    ).property('base', 'title')

    now: new Date()

    setupDate: ( ->
      setInterval =>
        Ember.run.next =>
          @set 'now', new Date()
      , 1000
    ).on('init')

    availableStatus: ( ->
      lockPassed = @get('lock_at') && (new Date(@get('lock_at')) < @get('now'))
      lockNotPassed = @get('lock_at') && (new Date(@get('lock_at')) > @get('now'))
      unlockPassed = @get('unlock_at') && (new Date(@get('unlock_at')) < @get('now'))
      if lockPassed
        'closed'
      else if @get('unlock_at') && (new Date(@get('unlock_at')) > @get('now'))
        'pending'
      else if (!@get('unlock_at') || unlockPassed) && lockNotPassed
        'availableUntil'
      else
        'none'
    ).property('unlock_at', 'lock_at', 'now')

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
        @get('lock_at')
      else if @get('availableStatus') == 'pending'
        @get('unlock_at')
      else
        ''
    ).property('availableStatus')

    dueLabel: ( ->
      if @get('due_at')
        I18n.t('due', 'Due')
    ).property('due_at')

    dueDate: Em.computed.alias 'due_at'
