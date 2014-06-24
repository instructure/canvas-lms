define [
  "../start_app"
  "ember"
], (startApp, Ember) ->

  App = null
  run = Ember.run
  container = null
  store = null
  quizSubmission = null

  module "QuizSubmission",

    setup: ->
      App = startApp()
      run ->
        container = App.__container__
        store = container.lookup "store:main"
        quizSubmission = store.createRecord "quiz_submission",
          id: "1"

    teardown: ->
      run App, "destroy"

   test "isCompleted", ->
     run -> quizSubmission.set "workflowState", "pending_review"
     ok quizSubmission.get("isCompleted")

     run -> quizSubmission.set "workflowState", "complete"

     ok quizSubmission.get("isCompleted")

     run -> quizSubmission.set "workflowState", "invalid"

     ok !quizSubmission.get("isCompleted")

   test "isComplete", ->

     run -> quizSubmission.set "workflowState", "pending_review"

     ok !quizSubmission.get("isComplete")

     run -> quizSubmission.set "workflowState", "complete"

     ok quizSubmission.get("isComplete")

   test "isUntaken", ->

     run -> quizSubmission.set "workflowState", "untaken"

     ok quizSubmission.get("isUntaken")

     run -> quizSubmission.set "workflowState", "complete"

     ok !quizSubmission.get("isUntaken")
