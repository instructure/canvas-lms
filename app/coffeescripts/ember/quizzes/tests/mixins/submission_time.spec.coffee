define [
  'ember'
  '../../mixins/submission_time'
], (Ember, SubmissionTime) ->

  minutesFromNow = (minutes) ->
    # 60000 ms per minute
    date = new Date(new Date().getTime() + (minutes * 60000))
    date.toISOString()

  buildMixinUser = (startedAt, finishedAt, timeLimit, okayToReload) ->
    okayToReload ||= false
    timeLimit ||= undefined
    Ember.Object.createWithMixins(SubmissionTime, {
      okayToReload: okayToReload
      quizSubmission:
        startedAt: startedAt
        finishedAt: finishedAt
        quiz:
          timeLimit: timeLimit
    })

  module "SubmissionTime"

  test 'isActive when startedAt but no finishedAt', ->
    fiveAgo = minutesFromNow(-5)
    subject = buildMixinUser(fiveAgo, undefined)
    equal subject.get('isActive'), true

  test 'not isActive when startedAt and finishedAt', ->
    fiveAgo = minutesFromNow(-5)
    oneAgo = minutesFromNow(-1)
    subject = buildMixinUser(fiveAgo, oneAgo)
    equal subject.get('isActive'), false

  test 'calculates current duration when not timed quiz and no finish time', ->
    fiveAgo = minutesFromNow(-5)
    subject = buildMixinUser(fiveAgo)
    calcCurrentSpy = sinon.spy(subject, 'calcCurrentSeconds')
    subject.updateRunningTime()
    equal(calcCurrentSpy.called, true, 'uses calcCurrentSeconds, to count submission duration')

  test 'closeOutSubmission makes quizSubmission no longer active', ->
    twoAgo = minutesFromNow(-2)
    subject = buildMixinUser(twoAgo, undefined, 2)
    subject.closeOutSubmission(twoAgo, 120)
    ok(!!subject.get('quizSubmission.finishedAt'), 'sets temp finishedAt time')
    equal(subject.get('isActive'), false)

  test 'timed quizzes should stop counting at zero seconds left', ->
    twoAgo = minutesFromNow(-2)
    now = minutesFromNow(0)
    subject = buildMixinUser(twoAgo, undefined, 2)
    subject.set('endAt', now)
    sinon.spy(subject, 'startStopRunningTime')
    subject.updateRunningTime()
    ok(!!subject.get('quizSubmission.finishedAt'), 'sets temp finishedAt time')
    equal(subject.get('quizSubmission.timeSpent'), 120)
    equal(subject.get('isActive'), false)

  test 'friendlySubmissionTime returns if there isnt a started submission', ->
    twoAgo = minutesFromNow(-2)
    subject = buildMixinUser(twoAgo)
    subject.set('hasSubmission', false)
    ok(!subject.get('friendlyTime'))

  test 'friendlySubmissionTime returns the lesser of time limit, and time spent', ->
    # when a user times out on a timed quiz and the modal window pops up, a few
    # seconds can pass. making sure to only display timeSpent <= timeLimit
    twoAgo = minutesFromNow(-2)
    subject = buildMixinUser(twoAgo, undefined, 2) #2 minute time limit
    subject.set('hasSubmission', true)
    subject.set('quizSubmission.timeSpent', 180) #180 seconds == 3 min
    res = subject.get('friendlyTime')
    equal(res, '02:00')

  test 'calcRemainingSeconds uses endAt to determine when a submission should end', ->
    twoAgo = minutesFromNow(-2)
    twoFromNow = minutesFromNow(2)
    subject = buildMixinUser(twoAgo)
    subject.set('hasSubmission', true)
    subject.set('quizSubmission.endAt', twoFromNow)
    res = subject.calcRemainingSeconds()
    equal(Math.round(res), 120)

  test 'isTimeExpired correctly determines if endAt has passed', ->
    twoAgo = minutesFromNow(-2)
    oneMinuteAgo = minutesFromNow(-1)
    subject = buildMixinUser(twoAgo, oneMinuteAgo)
    subject.set('hasSubmission', true)
    subject.set('quizSubmission.endAt', oneMinuteAgo)
    ok subject.isTimeExpired()
