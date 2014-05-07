define [
  '../../start_app'
  'ember'
  '../../../controllers/quiz/submission_row_controller'
  'ember-qunit'
  '../../environment_setup'
], (startApp, Ember, SubmissionRowController, emq) ->


  {run} = Ember

  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  emq.moduleFor('controller:quiz.submission_row', 'SubmissionRowController', {
    needs: ['controller:quiz']
    setup: ->
      App = startApp()
      emq.setResolver(Ember.DefaultResolver.create({namespace: App}))
      user =
          id: 1
          shortName: 'Wesley, Fred'
      @model = Ember.Object.create
        user: user
        quizSubmission:
          id: 1
          attempt: 2
          keptScore: 5
          quizPointsPossible: 8
          timeSpent: 60
          quiz:
            allowedAttempts: 5


      @subCtr = this.subject()
      @subCtr.get('controllers.quiz').set('model', {allowedAttempts: 10})
      @subCtr.set('model', @model)

      @blankSub =
        user: user
        quizSubmission: Ember.Object.create

      @get = (prop) ->
        @subCtr.get(prop)

    teardown: ->
      run App, 'destroy'
    }
  )

  emq.test 'sanity', ->
    equal(@subCtr.get('model'), @model)

  emq.test 'proxies attempt correctly', ->
    equal(@get('attempts'), 2)

  emq.test 'attempts returns default when no attempts', ->
    @subCtr.set('model', @blankSub)
    equal @get('attempt', '--')

  emq.test 'friendlyScore converted correctly', ->
    equal @get('friendlyScore'), '5 / 8'
    @subCtr.set('model', @blankSub)
    equal @get('friendlyScore'), undefined

  emq.test 'friendlyTime converts correctly', ->
    equal @get('friendlyTime'), '01:00'
    @subCtr.set('model', @blankSub)
    equal @get('friendlyTime'), undefined

  emq.test 'remainingAttempts formats correctly when user has submission', ->
    equal @get('remainingAttempts'), '3'

  emq.test 'remainingAttempts uses quiz value when no user submission', ->
    @subCtr.set('model', @blankSub)
    equal @get('remainingAttempts'), '10'


