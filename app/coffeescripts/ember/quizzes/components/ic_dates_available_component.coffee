define [
  'ember',
  '../shared/status_date',
  'i18n!dates_available_component',
], (Ember, StatusDate, I18n) ->

  # http://emberjs.com/guides/components/
  # http://emberjs.com/api/classes/Ember.Component.html

  IcDatesAvailableComponent = Ember.Component.extend

    tagName: 'span'

    allDates: []
    showDueDates: false
    linkHref: '#'
    multipleDatesTitle: I18n.t('multiple_dates', 'Multiple Dates')
    multipleDates: Em.computed.gt('allDates.length', 1)
    statusDates: Em.computed.map 'allDates', (item) ->
      StatusDate.create
        lockAt: item.get 'lockAt'
        unlockAt: item.get 'unlockAt'
        dueAt: item.get 'dueAt'
        base: item.get 'base'
        title: item.get 'title'

    multipleDatesLabel: ( ->
      if @get('showDueDates')
        I18n.t('due', 'Due')
      else
        I18n.t('available', 'Available')
    ).property('showDueDates')

    singleDateLabel: ( ->
      return '' if !@get('singleDate')
      label = if @get('showDueDates') then 'dueLabel' else 'availableLabel'
      @get('singleDate').get(label)
    ).property('showDueDates')

    singleDate: ( ->
      return undefined if !@get('statusDates') && !@get('statusDates')[0]
      @get('statusDates')[0]
    ).property('statusDates.@each')

    singleFormat: ( ->
      if @get('showDueDates')
        'date_at_time'
      else
        'short'
    ).property('showDueDates')

    singleDateValue: ( ->
      if @get('showDueDates')
        @getStatusDateProp 'dueDate'
      else
        @getStatusDateProp 'availableDate'
    ).property('showDueDates')

    getStatusDateProp: (prop) ->
      return '' if !@get('singleDate')
      @get('singleDate').get(prop)
