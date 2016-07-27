define [
  'i18n!grading_cell'
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'compiled/gradebook2/GradebookHelpers'
  'underscore'
  'ember'
  'jquery'
  'jquery.ajaxJSON'
], (I18n, GRADEBOOK_TRANSLATIONS, GradebookHelpers, _, Ember, $) ->

  GradingCellComponent = Ember.Component.extend

    value: null
    excused: null
    shouldSaveExcused: false

    isPoints: Ember.computed.equal('assignment.grading_type', 'points')
    isPercent: Ember.computed.equal('assignment.grading_type', 'percent')
    isLetterGrade: Ember.computed.equal('assignment.grading_type', 'letter_grade')
    isPassFail: Ember.computed.equal('assignment.grading_type', 'pass_fail')
    isInPastGradingPeriodAndNotAdmin: ( ->
      GradebookHelpers.gradeIsLocked(@assignment, ENV)
    ).property('assignment')
    nilPointsPossible: Ember.computed.none('assignment.points_possible')
    isGpaScale: Ember.computed.equal('assignment.grading_type', 'gpa_scale')

    passFailGrades: [
        {
          label: I18n.t "grade_ungraded", "Ungraded"
          value: "-"
        }
        {
          label: I18n.t "grade_complete", "Complete"
          value: "complete"
        }
        {
          label: I18n.t "grade_incomplete", "Incomplete"
          value: "incomplete"
        }
        {
          label: I18n.t "Excused"
          value: 'EX'
        }
    ]

    outOfText: (->
      if @submission && @submission.excused
        I18n.t "Excused"
      else if @get('isGpaScale')
        ""
      else if @get('isLetterGrade') or @get('isPassFail')
        I18n.t "out_of_with_score", "(%{score} out of %{points})",
          points: @assignment.points_possible
          score: @get('score')
      else if @get('nilPointsPossible')
        I18n.t "out_of_nil", "No points possible"
      else
        I18n.t "out_of", "(out of %{points})", points: @assignment.points_possible
    ).property('submission.score', 'assignment')

    changeGradeURL: ->
      ENV.GRADEBOOK_OPTIONS.change_grade_url

    saveURL: (->
      submission = @get('submission')
      this.changeGradeURL()
        .replace(":assignment", submission.assignment_id)
        .replace(":submission", submission.user_id)
    ).property('submission.assignment_id', 'submission.user_id')

    score: (->
      if @submission.score? then @submission.score else ' -'
    ).property('submission.score')

    ajax: (url, options) ->
      {type, data} = options
      $.ajaxJSON url, type, data

    excusedToggled: (->
      @updateSubmissionExcused() if @shouldSaveExcused
    ).observes('excused')

    updateSubmissionExcused: () ->
      url   = @get('saveURL')
      value = @$('#submission-excused')?[0].checked

      save = @ajax url,
        type: "PUT"
        data: {'submission[excuse]': value}
      save.then @boundUpdateSuccess, @onUpdateError

    setExcusedWithoutTriggeringSave: (isExcused) ->
      @shouldSaveExcused = false
      @set 'excused', isExcused
      @shouldSaveExcused = true

    submissionDidChange: (->
      newVal = if @submission?.excused
                 'EX'
               else
                 @submission?.grade || '-'

      @setExcusedWithoutTriggeringSave(@submission?.excused)
      @set 'value', newVal
    ).observes('submission').on('init')

    onUpdateSuccess: (submission) ->
      @sendAction 'on-submit-grade', submission.all_submissions

    onUpdateError: ->
      $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error)

    focusOut:(event) ->
      isGradeInput = event.target.id == 'student_and_assignment_grade'
      submission   = @get('submission')

      return unless submission && isGradeInput

      url = @get('saveURL')
      value = @$('input, select').val()
      @setExcusedWithoutTriggeringSave(value?.toUpperCase() == 'EX')
      if @get('isPassFail') and value == '-'
        value = ''
      return if value == submission.grade
      data = if value?.toUpperCase() == 'EX'
               { "submission[excuse]": true }
             else
               { "submission[posted_grade]": value }
      save = @ajax url,
        type: "PUT"
        data: data
      save.then @boundUpdateSuccess, @onUpdateError

    bindSave: (->
      @boundUpdateSuccess = _.bind(@onUpdateSuccess, this)
    ).on('init')

    click: (event) ->
      target = event.target
      hasCheckboxClass = target.classList[0] == 'checkbox'
      isCheckBox = target.type == 'checkbox'

      if hasCheckboxClass || isCheckBox
        @$('#submission-excused').focus()
      else
        @$('input, select').select()

    focus: ->
      @$('input, select').select()
