define [
  'i18n!grading_cell'
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'underscore'
  'ember'
  'jquery'
  'jquery.ajaxJSON'
], (I18n, GRADEBOOK_TRANSLATIONS, _, Ember, $) ->

  GradingCellComponent = Ember.Component.extend

    value: null

    isPoints: Ember.computed.equal('assignment.grading_type', 'points')
    isPercent: Ember.computed.equal('assignment.grading_type', 'percent')
    isLetterGrade: Ember.computed.equal('assignment.grading_type', 'letter_grade')
    isPassFail: Ember.computed.equal('assignment.grading_type', 'pass_fail')
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
    ]

    outOfText: (->
      if @get('isGpaScale')
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

    submissionDidChange: (->
      newVal = if @submission?.grade? then @submission.grade else '-'
      @set 'value', newVal
    ).observes('submission').on('init')

    onUpdateSuccess: (submission) ->
      @sendAction 'on-submit-grade', submission.all_submissions

    onUpdateError: ->
      $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error)

    focusOut: ->
      return unless submission = @get('submission')
      url = @get('saveURL')
      value = @$('input, select').val()
      if @get('isPassFail') and value == "-"
        value = ''
      return if value == submission.grade
      save = @ajax url,
        type: "PUT"
        data: { "submission[posted_grade]": value }
      save.then @boundUpdateSuccess, @onUpdateError

    bindSave: (->
      @boundUpdateSuccess = _.bind(@onUpdateSuccess, this)
    ).on('init')

    click: ->
      @$('input, select').select()

    focus: ->
      @$('input, select').select()
