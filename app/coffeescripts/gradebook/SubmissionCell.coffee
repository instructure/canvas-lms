#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'i18nObj'
  'jsx/shared/helpers/numberHelper'
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
  '../gradebook/GradebookTranslations'
  'jsx/grading/helpers/OutlierScoreHelper'
  'str/htmlEscape'
  '../gradebook/Turnitin'
  '../util/round'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers' # raw
], ($, _, I18n, numberHelper, GradeFormatHelper, GRADEBOOK_TRANSLATIONS,
  { default: OutlierScoreHelper }, htmlEscape, {extractDataTurnitin}, round) ->

  class SubmissionCell

    constructor: (@opts) ->
      @init()

    init: () ->
      submission = @opts.item[@opts.column.field]
      @$wrapper = $(@cellWrapper("<input #{@ariaLabelTemplate(submission.submission_type)} class='grade'/>")).appendTo(@opts.container)
      @$input = @$wrapper.find('input').focus().select()

    destroy: () ->
      @$input.remove()

    focus: () ->
      @$input.focus()

    loadValue: () ->
      @val = if @opts.item[@opts.column.field].excused
        "EX"
      else
        submission = @opts.item[@opts.column.field]
        grade = submission.grade || ''
        formattedGrade = GradeFormatHelper.formatGrade(grade, { gradingType: submission.gradingType })
        @val = htmlEscape(formattedGrade)
      @$input.val(@val)
      @$input[0].defaultValue = @val
      @$input.select()

    serializeValue: () ->
      @$input.val()

    applyValue: (item, state) ->
      submission = item[@opts.column.field]
      if state.toUpperCase() == "EX"
        submission.excused = true
      else
        submission.grade = htmlEscape state
        pointsPossible = numberHelper.parse(@opts.column.object.points_possible)
        score = numberHelper.parse(state)
        outlierScoreHelper = new OutlierScoreHelper(score, pointsPossible)
        $.flashWarning(outlierScoreHelper.warningMessage()) if outlierScoreHelper.hasWarning()
      @wrapper?.remove()
      @postValue(item, state)

    postValue: (item, state) ->
      submission = item[@opts.column.field]
      url = @opts.grid.getOptions().change_grade_url
      url = url.replace(":assignment", submission.assignment_id).replace(":submission", submission.user_id)
      data = if state.toUpperCase() == "EX"
        {"submission[excuse]": true}
      else
        {"submission[posted_grade]": GradeFormatHelper.delocalizeGrade(state)}
      $.ajaxJSON url, "PUT", data, @onUpdateSuccess, @onUpdateError

    onUpdateSuccess: (submission) ->
      $.publish('submissions_updated', [submission.all_submissions])

    onUpdateError: ->
      $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error)

    isValueChanged: () ->
      @val != @$input.val()

    validate: () ->
      { valid: true, msg: null }

    @formatter: (row, col, submission, assignment, student, opts = {}) ->
      if submission.excused
        grade = "EX"
      else
        grade = GradeFormatHelper.formatGrade(
          submission.grade,
          {
            gradingType: assignment?.grading_type,
            precision: round.DEFAULT
          }
        )

      this.prototype.cellWrapper(grade, {
        submission: submission,
        assignment: assignment,
        editable: false,
        student: student,
        isLocked: !!opts.isLocked,
        tooltip: opts.tooltip
      })

    cellWrapper: (innerContents, options = {}) ->
      opts = $.extend({}, {
        classes: '',
        editable: true,
        student: {
          isInactive: false,
          isConcluded: false,
        },
        isLocked: false
      }, options)
      opts.submission ||= @opts.item[@opts.column.field]
      opts.assignment ||= @opts.column.object
      submission_type = opts.submission.submission_type if opts.submission?.submission_type || null
      specialClasses = SubmissionCell.classesBasedOnSubmission(opts.submission, opts.assignment)
      specialClasses.push("grayed-out") if opts.student.isInactive || opts.student.isConcluded || opts.isLocked
      specialClasses.push("cannot_edit") if opts.student.isConcluded || opts.isLocked
      specialClasses.push(opts.tooltip) if opts.tooltip
      opts.editable = false if opts.student.isConcluded

      opts.classes += ' no_grade_yet ' unless opts.submission.grade && opts.submission.workflow_state != 'pending_review'
      innerContents = null if opts.submission.workflow_state == 'pending_review' && !isNaN(innerContents)
      innerContents ?= if submission_type then SubmissionCell.submissionIcon(submission_type, opts.submission.attachments) else '-'

      if turnitin = extractDataTurnitin(opts.submission)
        specialClasses.push('turnitin')
        innerContents += "<span class='gradebook-cell-turnitin #{htmlEscape turnitin.state}-score' />"

      tooltipText = $.map(specialClasses, (c)-> GRADEBOOK_TRANSLATIONS["submission_tooltip_#{c}"]).join ', '

      cellCommentHTML = if !opts.student.isConcluded && !opts.isLocked
        """
        <a href="#" data-user-id=#{opts.submission.user_id} data-assignment-id=#{opts.assignment.id} class="gradebook-cell-comment"><span class="gradebook-cell-comment-label hide-text">submission comments</span></a>
        """
      else
        ''

      """
      #{$.raw if tooltipText then '<div class="gradebook-tooltip">'+ htmlEscape(tooltipText) + '</div>' else ''}
      <div class="gradebook-cell #{htmlEscape if opts.editable then 'gradebook-cell-editable focus' else ''} #{htmlEscape opts.classes} #{htmlEscape specialClasses.join(' ')}">
        #{$.raw cellCommentHTML}
        #{$.raw innerContents}
      </div>
      """

    ariaLabelTemplate: (submission_type) ->
      label = GRADEBOOK_TRANSLATIONS["submission_tooltip_#{submission_type}"]
      if label?
        "aria-label='#{label}'"
      else
        ""

    @classesBasedOnSubmission: (submission={}, assignment={}) ->
      classes = []
      classes.push('resubmitted') if submission.grade_matches_current_submission == false
      classes.push('late') if submission.late
      classes.push('ungraded') if ''+assignment.submission_types is "not_graded"
      if assignment.anonymize_students
        classes.push('anonymous')
      else if assignment.moderation_in_progress
        classes.push('moderated')
      else if assignment.muted
        classes.push('muted')
      classes.push(submission.submission_type) if submission.submission_type
      classes

    @submissionIcon: (submission_type, attachments) ->
      klass = SubmissionCell.iconFromSubmissionType(submission_type)
      if attachments?
        workflow_state = attachments[0].workflow_state
        if workflow_state == "pending_upload"
          klass = "upload"
        else if workflow_state == "errored"
          klass = "warning"
      "<i class='icon-#{htmlEscape klass}' ></i>"

    @iconFromSubmissionType: (submission_type) ->
      switch submission_type
        when "online_upload"
          "document"
        when "discussion_topic"
          "discussion"
        when "online_text_entry"
          "text"
        when "online_url"
          "link"
        when "media_recording"
          "filmstrip"
        when "online_quiz"
          "quiz"
        else
          "document"

  class SubmissionCell.out_of extends SubmissionCell
    init: () ->
      submission = @opts.item[@opts.column.field]
      @$wrapper = $(@cellWrapper("""
        <div class="overflow-wrapper">
          <div class="grade-and-outof-wrapper">
            <input type="text" #{@ariaLabelTemplate(submission.submission_type)} class="grade"/>
            <span class="outof">
              <span class="divider">/</span>
              #{htmlEscape(I18n.n(@opts.column.object.points_possible))}
            </span>
          </div>
        </div>
      """, { classes: 'gradebook-cell-out-of-formatter' })).appendTo(@opts.container)
      @$input = @$wrapper.find('input').focus().select()

  class SubmissionCell.letter_grade extends SubmissionCell
    @formatter: (row, col, submission, assignment, student, opts={}) ->
      innerContents = if submission.excused
        "EX"
      else if submission.score?
        "#{htmlEscape submission.grade}<span class='letter-grade-points'>#{htmlEscape(I18n.n(submission.score))}</span>"
      else
        submission.grade

      SubmissionCell.prototype.cellWrapper(innerContents, {submission: submission, assignment: assignment, editable: false, student: student, isLocked: !!opts.isLocked, tooltip: opts.tooltip})

  class SubmissionCell.gpa_scale extends SubmissionCell
    @formatter: (row, col, submission, assignment, student, opts={}) ->
      innerContents = if submission.excused
        "EX"
      else
        submission.grade

      SubmissionCell.prototype.cellWrapper(innerContents, {submission: submission, assignment: assignment, editable: false, student: student, classes: "gpa_scale_cell", isLocked: !!opts.isLocked, tooltip: opts.tooltip})

  passFailMessage = (text) ->
    switch text
      when 'EX' then GRADEBOOK_TRANSLATIONS.submission_excused
      when '' then GRADEBOOK_TRANSLATIONS.submission_blank
      else GRADEBOOK_TRANSLATIONS["submission_#{text}"]

  iconClassFromSubmission = (submission) ->
    { pass: 'icon-check', complete: 'icon-check', fail: 'icon-x', incomplete: 'icon-x' }[submission.rawGrade] || 'icon-undefined'

  class SubmissionCell.pass_fail extends SubmissionCell

    states = ['pass', 'fail', '']
    STATE_MAPPING =
      pass: 'pass'
      complete: 'pass'
      fail: 'fail'
      incomplete: 'fail'

    classFromSubmission = (submission) ->
      if submission.excused
        "EX"
      else
        { pass: 'pass', complete: 'pass', fail: 'fail', incomplete: 'fail' }[submission.rawGrade] || ''

    checkboxButtonTemplate = (iconClass) ->
      if _.isEmpty(iconClass)
        '-'
      else
        """
        <i class="#{htmlEscape iconClass}" role="presentation"></i>
        """

    htmlFromSubmission: (options={}) ->
      cssClass = classFromSubmission(options.submission)
      iconClass = iconClassFromSubmission(options.submission)
      editable = if options.editable
        'editable'
      else
        ''
      SubmissionCell::cellWrapper("""
        <button
          data-value="#{htmlEscape(options.submission.entered_grade || options.submission.grade || '')}"
          class="Button Button--icon-action gradebook-checkbox gradebook-checkbox-#{htmlEscape cssClass} #{htmlEscape(editable)}"
          type="button"
          aria-label="#{htmlEscape cssClass}"><span class="screenreader-only">#{htmlEscape(passFailMessage(cssClass))}</span>#{checkboxButtonTemplate(iconClass)}</button>
        """, options)

    @formatter: (row, col, submission, assignment, student, opts={}) ->
      return SubmissionCell.formatter.apply(this, arguments) unless submission.grade?
      pass_fail::htmlFromSubmission({ submission, assignment, editable: false, isLocked: opts.isLocked, tooltip: opts.tooltip })

    init: () ->
      @$wrapper = $(@cellWrapper())
      @$wrapper = $(@htmlFromSubmission({
        submission: @opts.item[@opts.column.field],
        assignment: @opts.column.object,
        editable: true})
      ).appendTo(@opts.container)
      @$input = @$wrapper.find('.gradebook-checkbox')
        .bind('click', (event) =>
          event.preventDefault()
          currentValue = @$input.data('value')
          if currentValue is 'complete'
            newValue = 'incomplete'
          else if currentValue is 'incomplete'
            newValue = ''
          else
            newValue = 'complete'
          @transitionValue(newValue)
        ).focus()

    destroy: () ->
      @$wrapper.remove()

    transitionValue: (newValue) ->
      @$input
        .removeClass('gradebook-checkbox-pass gradebook-checkbox-fail')
        .addClass('gradebook-checkbox-' + classFromSubmission(rawGrade: newValue))
        .addClass('dontblur')
        .attr('aria-label', passFailMessage(STATE_MAPPING[newValue]))
        .data('value', newValue)
      @$input.find('i')
        .removeClass()
        .addClass(iconClassFromSubmission(rawGrade: newValue))

    loadValue: () ->
      submission = @opts.item[@opts.column.field]
      @val = submission.entered_grade || submission.grade || ""

    serializeValue: () ->
      @$input.data('value')

    isValueChanged: () ->
      @val != @$input.data('value')

  class SubmissionCell.points extends SubmissionCell

  SubmissionCell
