define [
  'ember'
  'i18n!quiz'
  'jquery'
  '../shared/environment'
  'compiled/jquery.rails_flash_notifications'
], (Ember, I18n, $, env) ->

  {RSVP, K} = Ember
  {equal} = Ember.computed

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
    legacyQuizSubmissionVersionsReady: Ember.computed.and('quizSubmissionVersionsHtml', 'didLoadQuizSubmissionVersionsHtml')

    disabledMessage: I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")

    # preserve 'publishing' state by not directly binding to published attr
    showAsPublished: false

    displayPublished: (->
      @set('showAsPublished', @get('published'))
    ).observes('model')

    takeOrResumeMessage: (->
      if @get('quizSubmission.isCompleted')
        if @get('isSurvey')
          I18n.t 'take_the_survey_again', 'Take the Survey Again'
        else
          I18n.t 'take_the_quiz_again', 'Take the Quiz Again'
      else if @get('quizSubmission.isUntaken')
        if @get('isSurvey')
          I18n.t 'resume_the_survey', 'Resume the Survey'
        else
          I18n.t 'resume_the_quiz', 'Resume the Quiz'
      else
        if @get('isSurvey')
          I18n.t 'take_the_survey', 'Take the Survey'
        else
          I18n.t 'take_the_quiz', 'Take the Quiz'
    ).property('isSurvey', 'quizSubmisison.isUntaken')

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

    timeLimitWithMinutes: (->
      I18n.t('time_limit_minutes', "%{limit} minutes", {limit: @get("timeLimit")})
    ).property('timeLimit')

    # message students modal

    recipientGroups: (->
      [
        Ember.Object.create({
          id: 'submitted'
          name: I18n.t('students_who_have_taken_the_quiz', 'Students Who Have Taken the Quiz'),
        })
        Ember.Object.create({
          id: 'unsubmitted'
          name: I18n.t('student_who_have_not_taken_the_quiz', 'Students Who Have Not Taken the Quiz')
        })
      ]
    ).property('submittedStudents', 'unsubmittedStudents')

    recipients: (->
      if @get('selectedRecipientGroup') is 'submitted'
        @get('submittedStudents')
      else
        @get('unsubmittedStudents')
    ).property('selectedRecipientGroup', 'submittedStudents', 'unsubmittedStudents')

    showUnsubmitted: equal 'selectedRecipientGroup', 'unsubmitted'

    noRecipients: equal 'recipients.length', 0

    # /message students modal

    actions:
      takeQuiz: ->
        url = "#{@get 'takeQuizUrl'}&authenticity_token=#{ENV.AUTHENTICITY_TOKEN}"
        $('<form></form>').
          prop('action', url).
          prop('method', 'POST').
          appendTo("body").
          submit()

      speedGrader: ->
        window.location = @get 'speedGraderUrl'

      showStudentResults: ->
        @replaceRoute 'quiz.moderate'
        $.flashMessage I18n.t('now_on_moderate', 'This information is now found on the Moderate tab.')

      toggleLock: ->
        if @get('lockAt')
          @send('unlock')
        else
          @send('lock')

      preview: ->
        $('<form/>').
          attr('action', "#{@get('previewUrl')}&authenticity_token=#{ENV.AUTHENTICITY_TOKEN}").
          attr('method', 'POST').
          appendTo('body').
          submit()

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
          @transitionToRoute 'quizzes'

      # message students modal

      sendMessageToStudents: ->
        $.ajax
          url: @get('messageStudentsUrl')
          data: JSON.stringify(
            conversations: [
              recipients: @get('selectedRecipientGroup')
              body: @get('messageBody')
            ]
          )
          type: 'POST'
          dataType: 'json'
          contentType: 'application/json'
        $.flashMessage I18n.t 'message_sent', 'Message Sent'

      # For modal, just do nothing.
      cancel: K
      # /message students modal

    # Kind of a gross hack so we can get quiz arrows in...
    addLegacyJS: (->
      return unless @get('quizSubmissionHTML.html')
      Ember.$(document.body).append """
        <script src="/javascripts/compiled/bundles/quiz_show.js"></script>
      """
    ).observes('quizSubmissionHTML.html')
