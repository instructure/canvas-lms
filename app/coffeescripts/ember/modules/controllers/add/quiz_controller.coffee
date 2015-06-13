define [
  './base_controller'
  'i18n!add_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  AddQuizController = Base.extend

    # TODO: should move this to a model or something, or cache by URLs
    quizzes: (->
      @constructor.quizzes or= fetch("/api/v1/courses/#{ENV.course_id}/quizzes")
    ).property()

    title: (->
      I18n.t('add_quiz_to', "Add a quizzes to %{module}", module: @get('moduleController.name'))
    ).property('moduleController.name')

    actions:

      toggleSelected: (quiz) ->
        quizzes = @get('model.selected')
        if quizzes.contains(quiz)
          quizzes.removeObject(quiz)
        else
          quizzes.addObject(quiz)

  AddQuizController.reopenClass

    quizzes: null

