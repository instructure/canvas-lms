define [
  '../start_app'
  'ember'
  '../../controllers/quiz_controller'
  'ember-qunit'
  '../environment_setup'
], (startApp, Ember, QuizController, emq) ->

  {run} = Ember

  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  # 86400000 ms in 24 hours
  yesterday = new Date(new Date().getTime() - 86400000)
  tomorrow = new Date(new Date().getTime() + 86400000)
  twoDaysOut = new Date(new Date().getTime() + (86400000 * 2))

  setDates = (unlock, lock) ->
    @qc.get('model').set('unlockAt', unlock)
    @qc.get('model').set('lockAt', lock)

  testDateEquality = (one, two, withinMS = 100) ->
    withinRange = Math.abs(one - two) < withinMS
    if one == null || two == null
      equal one, two, 'both dates are null'
    else
      ok withinRange, "#{one.toISOString()} && #{two.toISOString()} are close enough to be considered the same (within #{withinMS} ms apart)"

  emq.moduleFor('controller:quiz', 'QuizController', {
    setup: ->
      App = startApp()
      emq.setResolver(Ember.DefaultResolver.create({namespace: App}))
      @model = Ember.Object.create
        unlockAt: yesterday
        lockAt: tomorrow
        save: ->
          then: (func) ->
            func.call(@model)

      @qc = this.subject()
      @qc.set('model', @model)

    teardown: ->
      run App, 'destroy'
  })

  emq.test 'sanity', ->
    ok(@qc)

  # locking an unlocked quizzes
  emq.test 'when unlocked quiz, toggleLock calls lock', ->
    @qc.set 'isLocked', false
    wasCalled = false
    old = @qc._actions.lock
    @qc._actions.lock = ->
      wasCalled = true
    Ember.run =>
      @qc.send('toggleLock')
      equal wasCalled, true
      @qc._actions.lock = old

  emq.test 'lock action: sets lockAt to now', ->
    setDates.call(this, yesterday, tomorrow)
    equal @qc.get('isLocked'), false
    @qc.send('lock')
    testDateEquality(@qc.get('lockAt'), new Date())

  emq.test 'lock action: sets dueAt to now if it doesnt exist', ->
    setDates.call(this, yesterday, tomorrow)
    equal @qc.get('isLocked'), false
    @qc.send('lock')
    testDateEquality(@qc.get('dueAt'), new Date())

  emq.test 'lock action: doesnt sets dueAt if it exist', ->
    setDates.call(this, yesterday, tomorrow)
    equal @qc.get('isLocked'), false
    @qc.set('dueAt', yesterday)
    @qc.send('lock')
    testDateEquality(@qc.get('dueAt'), yesterday)

  emq.test 'lock action: sets dueAt to now if it exist, but is in the future', ->
    setDates.call(this, yesterday, tomorrow)
    equal @qc.get('isLocked'), false
    @qc.set('dueAt', tomorrow)
    @qc.send('lock')
    testDateEquality(@qc.get('dueAt'), new Date())

  # unlocking a locked quizzes
  emq.test 'when locked quiz, toggleLock calls unlock', ->
    @qc.set 'isLocked', true
    wasCalled = false
    old = @qc._actions.unlock
    @qc._actions.unlock = ->
      wasCalled = true
    @qc.send('toggleLock')
    equal wasCalled, true
    @qc._actions.unlock = old

  emq.test 'unlock action: sets unlock to now when set to something in the future', ->
    setDates.call(this, tomorrow, twoDaysOut)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('unlockAt'), new Date())

  emq.test 'unlock action: doesnt sets unlock when it doesnt exist', ->
    setDates.call(this, null, yesterday)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('unlockAt'), null)

  emq.test 'unlock action: doesnt sets unlock when it is has already passed', ->
    setDates.call(this, yesterday, yesterday)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('unlockAt'), yesterday)

  emq.test 'unlock action: removes lockAt when it is a past date', ->
    setDates.call(this, yesterday, yesterday)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('lockAt'), null)

  emq.test 'unlock action: leaves lockAt unchanged when it was already null', ->
    setDates.call(this, tomorrow, null)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('lockAt'), null)

  emq.test 'unlock action: leaves lockAt unchanged when it is a future date', ->
    setDates.call(this, tomorrow, twoDaysOut)
    equal @qc.get('isLocked'), true
    @qc.send('unlock')
    testDateEquality(@qc.get('lockAt'), twoDaysOut)
