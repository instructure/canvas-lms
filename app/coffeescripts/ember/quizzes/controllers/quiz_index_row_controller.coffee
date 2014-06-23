define [
  'ember',
  'i18n!quiz_index_row',
  '../shared/environment'
], (Ember, I18n, environment) ->

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  QuizIndexRowController = Ember.ObjectController.extend

    # preserve 'publishing' state by not directly binding to published attr
    showAsPublished: false

    needs: ['quizzes']

    questionCountLabel: (->
      I18n.t('questions', 'Question', count: @get('questionCount'))
    ).property('question_count')

    isPublishedStatusVisible: ( ->
      @get('published') && @get('canUpdate')
    ).property('published', 'canUpdate')

    disabled: (->
      !@get('unpublishable')
    ).property('unpublishable')

    disabledMessage: I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")

    editTitle: I18n.t('edit_quiz', 'Edit Quiz')
    deleteTitle: I18n.t('delete_quiz', 'Delete Quiz')

    editUrl: (->
      @get('htmlURL') + "/edit"
    ).property('htmlURL')

    pointsPossible: (->
      return '' unless pointsPossible = @get('model.pointsPossible')
      I18n.t('points', 'pt', count: pointsPossible)
    ).property('model.pointsPossible')

    displayPublished: (->
      @set('showAsPublished', @get('published'))
    ).on('init')

    updatePublished: (publishStatus) ->
      success = (=> @displayPublished())

      # they're not allowed to unpublish
      failed = =>
        @set 'published', true
        @set 'unpublishable', false
        @displayPublished()

      @set 'published', publishStatus
      @get('model').save().then success, failed

    actions:
      publish: ->
        @updatePublished true

      unpublish: ->
        @updatePublished false

      edit: ->
        window.location = @get('editUrl')

      delete: ->
        if window.confirm I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?')
          model = @get 'model'
          model.deleteRecord()
          model.save()
          @get('controllers.quizzes').removeObject(model)


