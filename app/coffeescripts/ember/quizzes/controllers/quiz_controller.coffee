define [
  'ember'
  '../mixins/legacy_submission_html'
  '../shared/is_locked'
  'i18n!quiz'
  'jquery'
  '../shared/environment'
  'compiled/behaviors/authenticity_token'
  'compiled/jquery.rails_flash_notifications'
  'compiled/bundles/submission_download'
], (Ember, LegacySubmissions, isQuizLocked, I18n, $, env, authenticity_token) ->

  QuizController = Ember.ObjectController.extend LegacySubmissions, Ember.Evented,
    disabledMessage: I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")

    # preserve 'publishing' state by not directly binding to published attr
    showAsPublished: false

    isLocked: (->
      isQuizLocked(@get('unlockAt'), @get('lockAt'))
    ).property('unlockAt', 'lockAt')

    displayPublished: (->
      @set('showAsPublished', @get('published'))
    ).observes('model')

    moderateEnabled: (->
      env.get("moderateEnabled")
    ).property()

    speedGraderActive: (->
      @get('studentQuizSubmissions.length')
    ).property('studentQuizSubmissions.length')

    downloadActive: (->
      !!@get('quizSubmissionsZipUrl')
    ).property('quizSubmissionsZipUrl')

    takeQuizActive: (->
      @get('published') and @get('takeable') and !@get('lockedForUser')
    ).property('published', 'takeable', 'lockedForUser')

    messageStudentsActive: (->
      @get('published')
    ).property('published')

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

    submissionHasRegrade: (->
      score = @get('quizSubmission.scoreBeforeRegrade')
      score != null and score >= 0
    ).property('quizSubmission.scoreBeforeRegrade')

    scoreAffectedByRegradeLabel: (->
      if @get('quizSubmission.scoreBeforeRegrade') != @get('quizSubmission.keptScore')
        since = @get('quizSubmission.questionsRegradedSinceLastAttempt')
        if since == 1
          I18n.t('regrade_score_affected', 'This quiz has been regraded; your score was affected.')
        else
          I18n.t('regrade_count_affected', 'This quiz has been regraded; your new score reflects %{num} questions that were affected.', num: since)
      else
        I18n.t('quiz_regraded_your_score_not_affected', "This quiz has been regraded; your score was not affected.")

    ).property('quizSubmission.scoreBeforeRegrade', 'quizSubmission.keptScore', 'quizSubmission.questionsRegradedSinceLastAttempt')

    warningText: (->
      I18n.t 'warning', 'Warning'
    ).property()

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

    actions:
      takeQuiz: ->
        if @get 'takeQuizActive'
          url = "#{@get 'takeQuizUrl'}&authenticity_token=#{authenticity_token()}"
          $('<form></form>').
            prop('action', url).
            prop('method', 'POST').
            appendTo("body").
            submit()
        else
          msg = if !@get('published')
            I18n.t('cant_take_unpublished_quiz', "You can't take a quiz until it is published")
          else
            I18n.t('no_more_allowed_quiz_attempts', "You aren't allowed any more attempts on this quiz.")
          $.flashWarning(msg)

      speedGrader: ->
        if @get 'speedGraderActive'
          window.location = @get 'speedGraderUrl'
        else
          $.flashWarning I18n.t('there_are_no_submissions_to_grade', 'There are no submissions to grade.')

      messageStudents: ->
        if !@get('messageStudentsActive')
          $.flashWarning I18n.t('you_cannot_message_unpublished', 'You can not message students until this quiz is published.')
        else
          true

      moderateQuiz: ->
        window.location = @get 'moderateUrl'

      downloadFiles: ->
        if @get 'downloadActive'
          INST.downloadSubmissions(@get('quizSubmissionsZipUrl'))
        else
          $.flashWarning I18n.t('there_are_no_files_to_download', 'There are no files to download.')

      showStudentResults: ->
        @replaceRoute 'quiz.moderate'
        $.flashMessage I18n.t('now_on_moderate', 'This information is now found on the Moderate tab.')

      preview: ->
        $('<form/>').
          attr('action', "#{@get('previewUrl')}&authenticity_token=#{authenticity_token()}").
          attr('method', 'POST').
          appendTo('body').
          submit()

      toggleLock: ->
        if @get('isLocked')
          @send('unlock')
        else
          @send('lock')

      lock: ->
        # skipping assignment overrides for now...
        # TODO: need a quizzes assignment overrides endpoint
        now = new Date()
        prevDueAt = @get('dueAt')
        if !prevDueAt || prevDueAt > now
          @set('dueAt', now)
        @set 'lockAt', now
        @get('model').save().then ->
          $.flashMessage I18n.t('quiz_successfully_updated', 'Quiz Successfully Updated!')

      unlock: ->
        # skipping assignment overrides for now...
        # TODO: need a quizzes assignment overrides endpoint
        now = new Date()
        unlock = @get 'unlockAt'
        lock = @get 'lockAt'
        if unlock && unlock > now
          @set 'unlockAt', now
        if lock && lock < now
          @set 'lockAt', null
        @get('model').save().then ->
          $.flashMessage I18n.t('quiz_successfully_updated', 'Quiz Successfully Updated!')

      publish: ->
        @updatePublished true

      unpublish: ->
        @updatePublished false

      delete: ->
        model = @get 'model'
        model.deleteRecord()
        model.save().then =>
          $.flashMessage I18n.t('quiz_successfully_deleted', 'Quiz Successfully Deleted!')

        @transitionToRoute 'quizzes'
        return # explicit return is necessary here

      showRubric: ->
        @trigger('rubricDisplayRequest')

    # Temporary while we are bringing in existing non-ember rubrics
    rubricActionUrl: (->
      "/courses/#{env.get('courseId')}/rubrics"
    ).property('env.courseId')

    rubricUrl: ( ->
      courseId = env.get('courseId')
      quizId = @get('id')
      assignmentId = @get('assignmentId')
      "/courses/#{courseId}/assignments/#{assignmentId}/rubric"
    ).property('env.courseId')
