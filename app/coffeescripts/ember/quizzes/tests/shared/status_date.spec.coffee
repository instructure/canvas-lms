define [
  '../../shared/status_date',
  '../date_string_offset'
], (StatusDate, dateString) ->

  module 'status_date',
    setup: ->

  test 'dueFor defaults when base is present', ->
    sDate = StatusDate.create
      base: true
    equal sDate.get('datesFor'), 'Everyone else'

  test 'dueFor returns title when base is not present', ->
    sDate = StatusDate.create
      title: 'Test Group'
    equal sDate.get('datesFor'), 'Test Group'

  test 'availableStatus closed', ->
    sDate = StatusDate.create
      lock_at: dateString(-1),
      unlock_at: dateString(-1)
    equal sDate.get('availableStatus'), 'closed'

  test 'availableStatus pending', ->
    sDate = StatusDate.create
      lock_at: dateString(2)
      unlock_at: dateString(1)
    equal sDate.get('availableStatus'), 'pending'

  test 'availableStatus none', ->
    sDate = StatusDate.create
      unlock_at: dateString(-1)
    equal sDate.get('availableStatus'), 'none'

  test 'availableStatus availableUntil', ->
    sDate = StatusDate.create
      unlock_at: dateString(-1)
      lock_at: dateString(1)
    equal sDate.get('availableStatus'), 'availableUntil'

  test 'availableStatus none', ->
    sDate = StatusDate.create({})
    equal sDate.get('availableStatus'), 'none'

  test 'availableLabel available', ->
    sDate = StatusDate.create
      availableStatus: 'available'
    equal sDate.get('availableLabel'), 'Available'

  test 'availableLabel availableUntil', ->
    sDate = StatusDate.create
      availableStatus: 'availableUntil'
    equal sDate.get('availableLabel'), 'Available until'

  test 'availableLabel pending', ->
    sDate = StatusDate.create
      availableStatus: 'pending'
    equal sDate.get('availableLabel'), 'Not available until'

  test 'availableMultiLabel pending', ->
    sDate = StatusDate.create
      availableStatus: 'pending'
    equal sDate.get('availableMultiLabel'), 'Available on'

  test 'availableLabel closed', ->
    sDate = StatusDate.create
      availableStatus: 'closed'
    equal sDate.get('availableLabel'), 'Closed'

  test 'availableLabel none', ->
    sDate = StatusDate.create
      availableStatus: 'none'
    equal sDate.get('availableLabel'), ''

  test 'availableMultiLabel none', ->
    sDate = StatusDate.create
      availableStatus: 'available'
    equal sDate.get('availableMultiLabel'), 'Available'

