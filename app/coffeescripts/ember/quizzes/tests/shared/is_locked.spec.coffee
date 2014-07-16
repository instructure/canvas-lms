define [
  '../../shared/is_locked'
], (isLocked) ->

  minutesFromNow = (minutes) ->
    # 60000 ms per minute
    new Date(new Date().getTime() + (minutes * 60000))

  module 'Unit: is_locked module'

  # both undefined
  test 'no unlockAt with no lockAt is not locked', ->
    equal isLocked(undefined, undefined), false

  # no unlockAt
  test 'no unlockAt with passed lockAt is locked', ->
    equal isLocked(undefined, minutesFromNow(-1)), true

  test 'no unlockAt with future lockAt is not locked', ->
    equal isLocked(undefined, minutesFromNow(1)), false

  # both unlockAt and lockAt (note future unlockAt and passed lockAt is not possible due to validations)
  test 'future unlockAt with future lockAt is locked', ->
    equal isLocked(minutesFromNow(1), minutesFromNow(2)), true

  test 'passed unlockAt with future lockAt is not locked', ->
    equal isLocked(minutesFromNow(-1), minutesFromNow(2)), false

  test 'passed unlockAt with passed lockAt is not locked', ->
    equal isLocked(minutesFromNow(-2), minutesFromNow(-1)), true

  # no lockAt
  test 'future unlockAt with no lockAt is locked', ->
    equal isLocked(minutesFromNow(1), undefined), true

  test 'passed unlockAt with no lockAt is not locked', ->
    equal isLocked(minutesFromNow(-1), undefined), false
