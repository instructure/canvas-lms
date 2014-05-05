define [
  'ember'
  'i18n!quizzes'
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], (Ember, I18n, $) ->

  {RSVP, K} = Ember

  updateAllDates = (field) ->
    date = new Date()
    @set field, date
    promises = []
    # skipping assignment overrides for now...
    # TODO: need a quizzes assignment overrides endpoint
    # promises = @get('assignmentOverrides').map (override) ->
    #  override.set field, date
    #  override.save()
    promises.pushObject(@get('model').save())
    RSVP.all promises

  QuizController = Ember.ObjectController.extend
    disabledMessage: I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")

    # preserve 'publishing' state by not directly binding to published attr
    showAsPublished: false

    displayPublished: (->
      @set('showAsPublished', @get('published'))
    ).observes('model')

    updatePublished: (publishStatus) ->
      success = (=> @displayPublished())

      # they're not allowed to unpublish
      failed = =>
        @set 'published', true
        @set 'unpublishable', false
        @displayPublished()

      @set 'published', publishStatus
      @get('model').save().then success, failed

    deleteTitle: (->
      I18n.t 'delete_quiz', 'Delete Quiz'
    ).property()

    confirmText: (->
      I18n.t 'delete', 'Delete'
    ).property()

    cancelText: (->
      I18n.t 'cancel', 'Cancel'
    ).property()

    recipientGroups: (->
      [@get('submittedStudents'), @get('unsubmittedStudents')]
    ).property('submittedStudents', 'unsubmittedStudents')

    actions:
      speedGrader: ->
        window.location = @get 'speedGraderUrl'

      lock: ->
        updateAllDates.call(this, 'lockAt').then ->
          $.flashMessage I18n.t('quiz_successfully_updated', 'Quiz Successfully Updated!')

      unlock: ->
        @set 'lockAt', null
        @get('assignmentOverrides').forEach (override) ->
          override.set 'lockAt', null
        updateAllDates.call(this, 'unlockAt').then ->
          $.flashMessage I18n.t('quiz_successfully_updated', 'Quiz Successfully Updated!')

      publish: ->
        @updatePublished true

      unpublish: ->
        @updatePublished false

      delete: ->
        model = @get 'model'
        model.deleteRecord()
        model.save().then =>
          @transitionTo 'quizzes'

      # For modal, just do nothing.
      cancel: K

    # Kind of a gross hack so we can get quiz arrows in...
    addLegacyJS: (->
      return unless @get('quizSubmissionHTML.html')
      Ember.$(document.body).append """
        <script src="/javascripts/compiled/bundles/quiz_show.js"></script>
      """
    ).observes('quizSubmissionHTML.html')
