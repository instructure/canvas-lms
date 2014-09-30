require [
  'i18n!quizzes'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/quizzes/QuizItemGroupView'
  'compiled/views/quizzes/NoQuizzesView'
  'compiled/views/quizzes/IndexView'
  'compiled/collections/QuizCollection'
  'compiled/models/QuizOverrideLoader'
  'compiled/util/vddTooltip'
], (I18n, $, _, Backbone, QuizItemGroupView, NoQuizzesView, IndexView, QuizCollection, QuizOverrideLoader, vddTooltip) ->

  class QuizzesIndexRouter extends Backbone.Router
    routes:
      '': 'index'

    translations:
      assignmentQuizzes: I18n.t('headers.assignment_quizzes', 'Assignment Quizzes')
      practiceQuizzes:   I18n.t('headers.practice_quizzes', 'Practice Quizzes')
      surveys:           I18n.t('headers.surveys', 'Surveys')
      toggleMessage:     I18n.t('toggle_message', 'toggle quiz visibility')

    initialize: ->
      @allQuizzes = ENV.QUIZZES

      @quizzes =
        assignment: @createQuizItemGroupView(
          @allQuizzes.assignment, @translations.assignmentQuizzes, 'assignment'
        )
        open: @createQuizItemGroupView(
          @allQuizzes.open, @translations.practiceQuizzes, 'open'
        )
        surveys: @createQuizItemGroupView(
          @allQuizzes.surveys, @translations.surveys, 'surveys'
        )
        noQuizzes:
          new NoQuizzesView

    index: ->
      @view = new IndexView
        assignmentView:  @quizzes.assignment
        openView:        @quizzes.open
        surveyView:      @quizzes.surveys
        noQuizzesView:   @quizzes.noQuizzes
        permissions:     ENV.PERMISSIONS
        flags:           ENV.FLAGS
        urls:            ENV.URLS
      @view.render()
      @loadOverrides() if @shouldLoadOverrides()

    loadOverrides: ->
      quizModels = [ 'assignment', 'open', 'surveys' ].reduce (out, quizType) =>
        out.concat(@quizzes[quizType].collection.models)
      , []

      QuizOverrideLoader(quizModels, ENV.URLS.assignment_overrides)

    createQuizItemGroupView: (collection, title, type) ->
      options = @allQuizzes.options

      # get quiz attributes from root container and add options
      new QuizItemGroupView
        collection: new QuizCollection(_.map(collection, (quiz) ->
          $.extend(quiz, options[quiz.id])
        ))
        isSurvey: type is 'surveys'
        listId: "#{type}-quizzes"
        title: title
        toggleMessage: @translations.toggleMessage

    shouldLoadOverrides: ->
      true

  # Start up the page
  router = new QuizzesIndexRouter
  Backbone.history.start()

  vddTooltip()
