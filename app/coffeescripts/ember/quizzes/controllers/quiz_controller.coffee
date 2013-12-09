define [
  'ember',
  'i18n!quizzes_model',
  'ic-ajax',
  '../shared/environment'
], (Ember, I18n, ajax, environment) ->

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  QuizController = Ember.ObjectController.extend

    needs: ['quizzes']

    questionCountLabel: (->
      I18n.t('questions', 'Question', count: @get('question_count'))
    ).property('question_count')

    canUpdate: true

    publishable: (->
      !@get('unpublishable')
    ).property('unpublishable')

    editTitle: I18n.t('edit_quiz', 'Edit Quiz')
    deleteTitle: I18n.t('delete_quiz', 'Delete Quiz')

    editUrl: (->
      @get('html_url') + "/edit"
    ).property('html_url')

    deleteUrl: (->
      @get('html_url')
    ).property('html_url')

    pointsPossible: (->
      return '' if !@get('points_possible')
      I18n.t('points', 'pt', count: @get('points_possible'))
    ).property('points_possible')

    actions:
      edit: ->
        window.location = @get('editUrl')

      delete: ->
        ok = window.confirm I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?')
        quizzesController = @get('controllers.quizzes')
        if ok
          id = environment.get('courseId')
          ajax(
            url: "/api/v1/courses/#{id}/quizzes/#{@get('id')}"
            type: 'DELETE'
          ).then =>
            quizzesController.removeObject(@get('model'))
