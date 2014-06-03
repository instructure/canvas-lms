define [
  'ember'
  '../mixins/redirect'
  '../shared/environment'
  'i18n!quiz_route'
], (Ember, Redirect, env, I18n) ->

  QuizRoute = Ember.Route.extend Redirect,

    # redirect for deleted model
    afterModel: (quiz, transition) ->
      # set the quiz in the env so that we can use it for nested routes
      env.set("quizId", quiz.id)

      if quiz.get("deleted")
        quiz.unloadRecord()
        msg = I18n.t('that_quiz_has_been_deleted', 'That quiz has been deleted')
        @redirectTo('quizzes', msg)

    actions:
      # handle missing/unauthorized quizzes
      error: (error, transition) ->
        messages = Ember.A(["Not Found", "Unauthorized", "Authorization Required"])
        if messages.contains error.errorThrown.trim()
          msg = I18n.t('that_quiz_doesnt_exist', "That quiz doesn't exist")
          @redirectTo('quizzes', msg)

      # TODO: Create a DialogRoute that has this action.
      _destroyModal: ->
        @disconnectOutlet
          outlet: 'modal'
          parentView: 'application'

      confirmDeletion: ->
        @render 'confirm_delete',
          into: 'application'
          outlet: 'modal'

      messageStudents: ->
        @render 'quiz/message_students',
          into: 'application'
          outlet: 'modal'
