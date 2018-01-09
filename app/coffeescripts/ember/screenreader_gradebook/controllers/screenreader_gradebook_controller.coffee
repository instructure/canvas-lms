#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

define [
  'jquery'
  'react'
  'react-dom'
  'ic-ajax'
  '../../../util/round'
  '../../../userSettings'
  '../../shared/xhr/fetch_all_pages'
  '../../shared/xhr/parse_link_header'
  'i18n!sr_gradebook'
  'ember'
  'underscore'
  'timezone'
  '../../../AssignmentDetailsDialog'
  '../../../AssignmentMuter'
  'jsx/gradebook/CourseGradeCalculator'
  'jsx/gradebook/EffectiveDueDates'
  '../../../gradebook/OutcomeGradebookGrid'
  '../../shared/components/ic_submission_download_dialog_component'
  'str/htmlEscape'
  '../../../models/grade_summary/CalculationMethodContent'
  'jsx/gradebook/SubmissionStateMap'
  '../../../api/gradingPeriodsApi'
  '../../../api/gradingPeriodSetsApi'
  'jsx/gradezilla/individual-gradebook/components/GradebookSelector'
  'jquery.instructure_date_and_time'
], (
  $, React, ReactDOM, 
  ajax, round, userSettings, fetchAllPages, parseLinkHeader, I18n, Ember, _, tz, AssignmentDetailsDialog,
  AssignmentMuter, CourseGradeCalculator, EffectiveDueDates, outcomeGrid, ic_submission_download_dialog,
  htmlEscape, CalculationMethodContent, SubmissionStateMap, GradingPeriodsApi, GradingPeriodSetsApi,
  GradebookSelector
) ->

  { get, set, setProperties } = Ember

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  gradingPeriodIsClosed = (gradingPeriod) ->
    new Date(gradingPeriod.close_date) < new Date()

  studentsUniqByEnrollments = (args...)->
    hiddenNameCounter = 1
    options =
      initialize: (array, changeMeta, instanceMeta) ->
        instanceMeta.students = {}
      addedItem: (array, enrollment, changeMeta, iMeta) ->
        student = iMeta.students[enrollment.user_id] or enrollment.user
        if !student.hiddenName?
          student.hiddenName = I18n.t("student_hidden_name", "Student %{position}", {position: hiddenNameCounter})
          hiddenNameCounter += 1
        student.sections ||= []
        student.sections.push(enrollment.course_section_id)
        student.role ||= enrollment.role
        return array if iMeta.students[student.id]
        iMeta.students[student.id] = student
        array.pushObject(student)
        array
      removedItem: (array, enrollment, _, instanceMeta)->
        student = array.findBy('id', enrollment.user_id)
        student.sections.removeObject(enrollment.course_section_id)

        if student.sections.length is 0
          delete instanceMeta.students[student.id]
          array.removeObject(student)
          hiddenNameCounter -= 1
        array
    args.push options
    Ember.arrayComputed.apply(null, args)

  contextUrl = get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')

  ScreenreaderGradebookController = Ember.ObjectController.extend
    init: ->
      @set('effectiveDueDates', Ember.ObjectProxy.create(content: {}))
      @set('assignmentsFromGroups', Ember.ArrayProxy.create(content: [], isLoaded: false))

    checkForCsvExport: (->
      currentProgress = get(window, 'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress')
      attachment = get(window, 'ENV.GRADEBOOK_OPTIONS.attachment')

      if currentProgress &&
         (currentProgress.progress.workflow_state != 'completed' &&
          currentProgress.progress.workflow_state != 'failed')

        attachmentProgress =
          progress_id: currentProgress.progress.id
          attachment_id: attachment.attachment.id

        $('#gradebook-export').prop('disabled', true)
        $('#last-exported-gradebook').hide()
        @pollGradebookCsvProgress(attachmentProgress)
    ).on('init')

    contextUrl: contextUrl
    uploadCsvUrl: "#{contextUrl}/gradebook_upload/new"

    lastGeneratedCsvAttachmentUrl: get(window, 'ENV.GRADEBOOK_OPTIONS.attachment_url')

    downloadOutcomeCsvUrl: "#{contextUrl}/outcome_rollups.csv"

    gradingHistoryUrl:"#{contextUrl}/gradebook/history"

    submissionsUrl: get(window, 'ENV.GRADEBOOK_OPTIONS.submissions_url')

    has_grading_periods: get(window, 'ENV.GRADEBOOK_OPTIONS.grading_period_set')?

    gradingPeriods:
      (->
        periods = get(window, 'ENV.GRADEBOOK_OPTIONS.active_grading_periods')
        deserializedPeriods = GradingPeriodsApi.deserializePeriods(periods)
        optionForAllPeriods =
          id: '0', title: I18n.t("all_grading_periods", "All Grading Periods")
        _.compact([optionForAllPeriods].concat(deserializedPeriods))
      )()

    getGradingPeriodSet: ->
      grading_period_set = get(window, 'ENV.GRADEBOOK_OPTIONS.grading_period_set')
      if grading_period_set
        GradingPeriodSetsApi.deserializeSet(grading_period_set)
      else
        null

    gradingPeriods: (->
      periods = get(window, 'ENV.GRADEBOOK_OPTIONS.active_grading_periods')
      deserializedPeriods = GradingPeriodsApi.deserializePeriods(periods)
      optionForAllPeriods =
        id: '0', title: I18n.t("all_grading_periods", "All Grading Periods")
      _.compact([optionForAllPeriods].concat(deserializedPeriods))
    )()

    lastGeneratedCsvLabel:  do () =>
      if get(window, 'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress')
        gradebook_csv_export_date = get(window, 'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress.progress.updated_at')
        I18n.t('Download Scores Generated on %{date}',
          {date: $.datetimeString(gradebook_csv_export_date)})

    selectedGradingPeriod: ((key, newValue) ->
      savedGradingPeriodId = userSettings.contextGet('gradebook_current_grading_period')
      if savedGradingPeriodId
        savedGP = @get('gradingPeriods').findBy('id', savedGradingPeriodId)
      if newValue
        userSettings.contextSet('gradebook_current_grading_period', newValue.id)
        newValue
      else if savedGP?
        savedGP
      else
        # default to current grading period, but don't change saved setting
        @get('gradingPeriods').findBy('id', ENV.GRADEBOOK_OPTIONS.current_grading_period_id)
    ).property()

    speedGraderUrl: (->
      "#{contextUrl}/gradebook/speed_grader?assignment_id=#{@get('selectedAssignment.id')}"
    ).property('selectedAssignment')

    studentUrl: (->
      "#{contextUrl}/grades/#{@get('selectedStudent.id')}"
    ).property('selectedStudent')

    showTotalAsPoints: (->
      ENV.GRADEBOOK_OPTIONS.show_total_grade_as_points
    ).property()

    publishToSisEnabled: (->
      ENV.GRADEBOOK_OPTIONS.publish_to_sis_enabled
    ).property()

    publishToSisURL:(->
      ENV.GRADEBOOK_OPTIONS.publish_to_sis_url
    ).property()

    teacherNotes: (->
      ENV.GRADEBOOK_OPTIONS.teacher_notes
    ).property().volatile()

    changeGradebookVersionUrl: (->
      "#{get(window, 'ENV.GRADEBOOK_OPTIONS.change_gradebook_version_url')}"
    ).property()

    hideOutcomes: (->
      !get(window, 'ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled')
    ).property()

    gradezilla: (->
      get window, 'ENV.GRADEBOOK_OPTIONS.gradezilla'
    ).property()

    showDownloadSubmissionsButton: (->
      hasSubmittedSubmissions     = @get('selectedAssignment.has_submitted_submissions')
      whitelist                   = ['online_upload','online_text_entry', 'online_url']
      submissionTypes             = @get('selectedAssignment.submission_types')
      submissionTypesOnWhitelist  = _.intersection(submissionTypes, whitelist)

      hasSubmittedSubmissions and _.any(submissionTypesOnWhitelist)
    ).property('selectedAssignment')

    hideStudentNames: false

    showConcludedEnrollments: (->
      userSettings.contextGet('show_concluded_enrollments') or false
    ).property().volatile()

    updateshowConcludedEnrollmentsSetting: ( ->
      isChecked = @get('showConcludedEnrollments')
      if isChecked?
        userSettings.contextSet 'show_concluded_enrollments', isChecked
    ).observes('showConcludedEnrollments')

    selectedAssignmentPointsPossible: ( ->
      I18n.n @get('selectedAssignment.points_possible')
    ).property('selectedAssignment')

    selectedStudent: null

    selectedSection: null

    selectedAssignment: null

    weightingScheme: null

    ariaAnnounced: null

    assignmentInClosedGradingPeriod: null

    disableAssignmentGrading: null

    actions:

      columnUpdated: (columnData, columnID) ->
        @updateColumnData columnData, columnID

      exportGradebookCsv: () ->
        $('#gradebook-export').prop('disabled', true)
        $('#last-exported-gradebook').hide()

        $.ajaxJSON(ENV.GRADEBOOK_OPTIONS.export_gradebook_csv_url, 'GET')
         .then((attachment_progress) => @pollGradebookCsvProgress(attachment_progress))

      gradeUpdated: (submissions) ->
        @updateSubmissionsFromExternal submissions

      selectItem: (property, item) ->
        @announce property, item

    pollGradebookCsvProgress: (attachmentProgress) ->
      self = this
      pollingProgress = setInterval(() =>
        $.ajaxJSON("/api/v1/progress/#{attachmentProgress.progress_id}", 'GET')
        .then((response) ->
          if response.workflow_state == 'completed'
            $.ajaxJSON("/api/v1/users/#{ENV.current_user_id}/files/#{attachmentProgress.attachment_id}", 'GET')
            .then((attachment) ->
              self.updateGradebookExportOptions(pollingProgress)
              document.getElementById('gradebook-export-iframe').src = attachment.url
              $('#last-exported-gradebook').attr('href', attachment.url)
            )

          if response.workflow_state == 'failed'
            self.updateGradebookExportOptions(pollingProgress)
        )
      , 2000)

    updateGradebookExportOptions: (pollingProgress) =>
      clearInterval pollingProgress
      $('#gradebook-export').prop('disabled', false)
      $('#last-exported-gradebook').show()

    announce: (prop, item) ->
      Ember.run.next =>
        if prop is 'student' and @get('hideStudentNames')
          text_to_announce = get item, 'hiddenName'
        else if prop is 'outcome'
          text_to_announce = get item, 'title'
        else
          text_to_announce = get item, 'name'
        @set 'ariaAnnounced', text_to_announce

    hideStudentNamesChanged: (->
      @set 'ariaAnnounced', null
    ).observes('hideStudentNames')

    setupSubmissionCallback: (->
      Ember.$.subscribe 'submissions_updated', _.bind(@updateSubmissionsFromExternal, this)
    ).on('init')

    setupAssignmentWeightingScheme: (->
      @set 'weightingScheme', ENV.GRADEBOOK_OPTIONS.group_weighting_scheme
    ).on('init')

    renderGradebookMenu: (->
      return unless @get('gradezilla')
      mountPoint = document.querySelector('[data-component="GradebookSelector"]')
      return unless mountPoint
      props =
        courseUrl: ENV.GRADEBOOK_OPTIONS.context_url
        learningMasteryEnabled: ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
      component = React.createElement(GradebookSelector, props)
      ReactDOM.render(component, mountPoint)
    ).on('init')

    willDestroy: ->
      Ember.$.unsubscribe 'submissions_updated'
      @_super()

    updateSubmissionsFromExternal: (submissions) ->
      subs_proxy = @get('submissions')
      selected = @get('selectedSubmission')
      studentsById = @groupById @get('students')
      assignmentsById = @groupById @get('assignments')
      submissions.forEach (submission) =>
        student = studentsById[submission.user_id]
        submissionsForStudent = subs_proxy.findBy('user_id', submission.user_id)
        oldSubmission = submissionsForStudent.submissions.findBy('assignment_id', submission.assignment_id)

        #check for DA visibility
        if submission.assignment_visible?
          set(submission, 'hidden', !submission.assignment_visible)
          @updateAssignmentVisibilities(assignmentsById[submission.assignment_id], submission.user_id)

        submissionsForStudent.submissions.removeObject oldSubmission
        submissionsForStudent.submissions.addObject submission
        @updateSubmission submission, student
        @calculateStudentGrade student
        if selected and selected.assignment_id == submission.assignment_id and selected.user_id == submission.user_id
          set(this, 'selectedSubmission', submission)

    updateAssignmentVisibilities: (assignment, userId) ->
      visibilities = get(assignment, 'assignment_visibility')
      filteredVisibilities = visibilities?.filter (id) ->
        id != userId
      set(assignment, 'assignment_visibility', filteredVisibilities)

    subtotalByGradingPeriod: ->
      selectedPeriodID = @get('selectedGradingPeriod.id')
      selectedPeriodID and selectedPeriodID == '0' and @periodsAreWeighted()

    calculate: (student) ->
      submissions = @submissionsForStudent(student)
      assignmentGroups = @assignmentGroupsHash()
      weightingScheme = @get('weightingScheme')
      gradingPeriodSet = @getGradingPeriodSet()
      effectiveDueDates = @get('effectiveDueDates.content')

      hasGradingPeriods = gradingPeriodSet and effectiveDueDates

      CourseGradeCalculator.calculate(
        submissions,
        assignmentGroups,
        weightingScheme,
        gradingPeriodSet if hasGradingPeriods,
        EffectiveDueDates.scopeToUser(effectiveDueDates, student.id) if hasGradingPeriods
      )

    submissionsForStudent: (student) ->
      allSubmissions = (value for key, value of student when key.match /^assignment_(?!group)/)
      return allSubmissions unless @get('has_grading_periods')
      selectedPeriodID = @get('selectedGradingPeriod.id')
      return allSubmissions if !selectedPeriodID or selectedPeriodID == '0'

      _.filter allSubmissions, (submission) =>
        studentPeriodInfo = @get('effectiveDueDates').get(submission.assignment_id)?[submission.user_id]
        studentPeriodInfo and studentPeriodInfo.grading_period_id == selectedPeriodID

    calculateSingleGrade: (student, key, gradeFinalOrCurrent) ->
      set(student, key, gradeFinalOrCurrent)
      if gradeFinalOrCurrent?.submissions
        for submissionData in gradeFinalOrCurrent.submissions
          set(submissionData.submission, 'drop', submissionData.drop)

    calculateStudentGrade: (student) ->
      if student.isLoaded
        grades = @calculate(student)

        selectedPeriodID = @get('selectedGradingPeriod.id')
        if selectedPeriodID && selectedPeriodID != '0'
          grades = grades.gradingPeriods[selectedPeriodID]

        finalOrCurrent = if @get('includeUngradedAssignments') then 'final' else 'current'

        if @subtotalByGradingPeriod()
          for gradingPeriodId, grade of grades.gradingPeriods
            @calculateSingleGrade(student, "grading_period_#{gradingPeriodId}", grade[finalOrCurrent])
        else
          for assignmentGroupId, grade of grades.assignmentGroups
            @calculateSingleGrade(student, "assignment_group_#{assignmentGroupId}", grade[finalOrCurrent])

        grades = grades[finalOrCurrent]

        percent = round (grades.score / grades.possible * 100), 2
        percent = 0 if isNaN(percent)
        setProperties student,
          total_grade: grades
          total_percent: percent

    calculateAllGrades: (->
      @get('students').forEach (student) => @calculateStudentGrade student
    ).observes(
      'includeUngradedAssignments','groupsAreWeighted', 'assignment_groups.@each.group_weight',
      'selectedGradingPeriod', 'gradingPeriods.@each.weight'
    )

    sectionSelectDefaultLabel: I18n.t "all_sections", "All Sections"
    studentSelectDefaultLabel: I18n.t "no_student", "No Student Selected"
    assignmentSelectDefaultLabel: I18n.t "no_assignment", "No Assignment Selected"
    outcomeSelectDefaultLabel: I18n.t "no_outcome", "No Outcome Selected"

    submissionStateMap: null

    assignment_groups: []
    assignment_subtotals: []
    subtotal_by_period: false

    fetchAssignmentGroups: (->
      params = { exclude_response_fields: ['in_closed_grading_period'] }
      gpId = @get('selectedGradingPeriod.id')
      if @get('has_grading_periods') && gpId != '0'
        params.grading_period_id = gpId
      @set('assignment_groups', [])
      @get('assignmentsFromGroups').setProperties(content: [], isLoaded: false)
      Ember.run.once =>
        fetchAllPages(get(window, 'ENV.GRADEBOOK_OPTIONS.assignment_groups_url'), { data: params, records: @get('assignment_groups') })
    ).observes('selectedGradingPeriod').on('init')

    pushAssignmentGroups: (subtotals) ->
      @set('subtotal_by_period', false)
      weighted = @get('groupsAreWeighted')
      for group in @get('assignment_groups')
        subtotal =
          name: group.name
          key: "assignment_group_#{group.id}"
          weight: weighted && group.group_weight
        subtotals.push(subtotal)

    pushGradingPeriods: (subtotals) ->
      @set('subtotal_by_period', true)
      weighted = @periodsAreWeighted()
      for period in @get('gradingPeriods')
        if period.id > 0
          subtotal =
            name: period.title
            key: "grading_period_#{period.id}"
            weight: weighted && period.weight
          subtotals.push(subtotal)

    assignmentSubtotals: (->
      subtotals = []
      if @subtotalByGradingPeriod()
        @pushGradingPeriods(subtotals)
      else
        @pushAssignmentGroups(subtotals)
      @set('assignment_subtotals', subtotals)
    ).observes('assignment_groups', 'gradingPeriods', 'selectedGradingPeriod', 'students.@each', 'selectedStudent').on('init')

    students: studentsUniqByEnrollments('enrollments')

    studentsHash: ->
      students = {}
      @get('students').forEach (s) ->
        unless s.role == "StudentViewEnrollment"
          students[s.id] = s
      students

    processLoadingSubmissions: (submissionGroups) ->
      submissions = []

      _.forEach submissionGroups, (submissionGroup) =>
        submissions.push(submissionGroup.submissions...)

      @updateEffectiveDueDatesFromSubmissions(submissions)
      assignmentIds = _.uniq(_.pluck(submissions, 'assignment_id'))
      assignmentMap = _.indexBy(@get('assignmentsFromGroups.content'), 'id')
      assignmentIds.forEach (assignmentId) =>
        assignment = assignmentMap[assignmentId]
        @updateEffectiveDueDatesOnAssignment(assignment) if assignment

      submissionGroups

    fetchStudentSubmissions: (->
      Ember.run.once =>
        notYetLoaded = @get('students').filter (student) ->
          return false if get(student, 'isLoaded') or get(student, 'isLoading')
          set(student, 'isLoading', true)
          student

        return unless notYetLoaded.length
        studentIds = notYetLoaded.mapBy('id')

        while (studentIds.length)
          chunk = studentIds.splice(0, ENV.GRADEBOOK_OPTIONS.chunk_size || 20)
          fetchAllPages(
            ENV.GRADEBOOK_OPTIONS.submissions_url,
            {
              data: { student_ids: chunk },
              process: (submissions) => @processLoadingSubmissions(submissions),
              records: @get('submissions')
            }
          )

    ).observes('students.@each', 'selectedGradingPeriod').on('init')

    showNotesColumn: (->
      notes = @get('teacherNotes')
      if notes
        !notes.hidden
      else
        false
    ).property().volatile()

    shouldCreateNotes: (->
      !@get('teacherNotes') and @get('showNotesColumn')
    ).property('teacherNotes', 'showNotesColumn', 'custom_columns.@each')

    notesURL: (->
      if @get('shouldCreateNotes')
        window.ENV.GRADEBOOK_OPTIONS.custom_columns_url
      else
        notesID = @get('teacherNotes')?.id
        window.ENV.GRADEBOOK_OPTIONS.custom_column_url.replace(/:id/, notesID)
    ).property('shouldCreateNotes', 'custom_columns.@each')

    notesParams: (->
      if @get('shouldCreateNotes')
        "column[title]": I18n.t("notes", "Notes")
        "column[position]": 1
        "column[teacher_notes]": true
      else
        "column[hidden]": !@get('showNotesColumn')
    ).property('shouldCreateNotes', 'showNotesColumn')

    notesVerb: (->
      if @get('shouldCreateNotes') then "POST" else "PUT"
    ).property('shouldCreateNotes')

    updateOrCreateNotesColumn: (->
      ajax.request(
        dataType: "json"
        type: @get('notesVerb')
        url: @get('notesURL')
        data: @get('notesParams')
      ).then @boundNotesSuccess
    ).observes('showNotesColumn')

    bindNotesSuccess:(->
      @boundNotesSuccess = _.bind(@onNotesUpdateSuccess, this)
    ).on('init')

    onNotesUpdateSuccess: (col) ->
      customColumns = @get('custom_columns')
      method = if col.hidden then 'removeObject' else 'unshiftObject'
      column = customColumns.findBy('id', col.id) or col
      customColumns[method] column

      if col.teacher_notes
        @set 'teacherNotes', col

      unless col.hidden
        ajax.request(
          url: ENV.GRADEBOOK_OPTIONS.reorder_custom_columns_url
          type:"POST"
          data:
            order: customColumns.mapBy('id')
        )

    groupsAreWeighted: (->
      @get("weightingScheme") == "percent"
    ).property("weightingScheme")

    periodsAreWeighted: ->
      !!@getGradingPeriodSet()?.weighted

    gradesAreWeighted: (->
      @get('groupsAreWeighted') or @periodsAreWeighted()
    ).property('weightingScheme')

    hidePointsPossibleForFinalGrade: (->
      !!(@get('groupsAreWeighted') or @subtotalByGradingPeriod())
    ).property("weightingScheme", "selectedGradingPeriod")

    updateShowTotalAs: (->
      @set "showTotalAsPoints", @get("showTotalAsPoints")
      ajax.request(
        dataType: "json"
        type: "PUT"
        url: ENV.GRADEBOOK_OPTIONS.setting_update_url
        data:
          show_total_grade_as_points: @get("showTotalAsPoints"))
    ).observes('showTotalAsPoints', 'gradesAreWeighted')

    studentColumnData: {}

    updateColumnData: (columnDatum, columnID) ->
      studentData = @get('studentColumnData')
      dataForStudent = studentData[columnDatum.user_id] or Ember.A()

      columnForStudent = dataForStudent.findBy('column_id', columnID)
      if columnForStudent
        columnForStudent.set 'content', columnDatum.content
      else
        dataForStudent.push Ember.Object.create
                              column_id: columnID
                              content: columnDatum.content
      studentData[columnDatum.user_id] = dataForStudent

    fetchColumnData: (col, url) ->
      url ||= ENV.GRADEBOOK_OPTIONS.custom_column_data_url.replace /:id/, col.id
      ajax.raw(url, {dataType:"json"}).then (result) =>
        for datum in result.response
          @updateColumnData datum, col.id
        meta = parseLinkHeader result.jqXHR
        if meta.next
          @fetchColumnData col, meta.next
        else
          setProperties col,
            'isLoading': false
            'isLoaded': true

    dataForStudent: (->
      selectedStudent = @get('selectedStudent')
      return unless selectedStudent?
      @get('studentColumnData')[selectedStudent.id]
    ).property('selectedStudent', 'custom_columns.@each.isLoaded')

    loadCustomColumnData: (->
      return unless (@get('enrollments.isLoaded'))
      @get('custom_columns').filter((col) ->
        return false if get(col, 'isLoaded') or get(col, 'isLoading')
        set col, 'isLoading', true
        col
      ).forEach (col) =>
        @fetchColumnData col
    ).observes('enrollments.isLoaded', 'custom_columns.@each')

    studentsInSelectedSection: (->
      students = @get('students')
      currentSection = @get('selectedSection')

      return students if not currentSection
      students.filter (s) -> s.sections.contains(currentSection.id)
    ).property('students.@each', 'selectedSection')

    groupById: (array) ->
      array.reduce( (obj, item) ->
        obj[get(item, 'id')] = item
        obj
      ,{})

    submissionsLoaded: (->
      assignments = @get("assignmentsFromGroups")
      assignmentsByID = @groupById assignments
      studentsByID = @groupById @get("students")
      submissions = @get('submissions')
      submissions.forEach ((submission) ->
        student = studentsByID[submission.user_id]
        if student?
          submission.submissions.forEach ((s) ->
            assignment = assignmentsByID[s.assignment_id]
            if !@differentiatedAssignmentVisibleToStudent(assignment, s.user_id)
              set s, 'hidden', true
            @updateSubmission(s, student)
          ), this
          # fill in hidden ones
          assignments.forEach ((a) ->
            if !@differentiatedAssignmentVisibleToStudent(a, student.id)
              sub = {
                user_id: student.id
                assignment_id: a.id
                hidden: true
              }
              @updateSubmission(sub, student)
          ), this
          setProperties student,
            'isLoading': false
            'isLoaded': true
          @calculateStudentGrade student
      ), this
    ).observes('submissions.@each')

    updateSubmission: (submission, student) ->
      submission.submitted_at = tz.parse(submission.submitted_at)
      set(student, "assignment_#{submission.assignment_id}", submission)

    updateEffectiveDueDatesOnAssignment: (assignment) ->
      assignment.effectiveDueDates = @get('effectiveDueDates.content')[assignment.id] || {}
      assignment.inClosedGradingPeriod = _.any(assignment.effectiveDueDates, (date) => date.in_closed_grading_period)

    updateEffectiveDueDatesFromSubmissions: (submissions) ->
      effectiveDueDates = @get('effectiveDueDates.content')
      gradingPeriods = @getGradingPeriodSet()?.gradingPeriods
      EffectiveDueDates.updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      @set('effectiveDueDates.content', effectiveDueDates)

    assignments: Ember.ArrayProxy.createWithMixins(
      Ember.SortableMixin, {
        content: []
        sortProperties: ['ag_position', 'position']
      }
    )

    processAssignment: (as, assignmentGroups) ->
      assignmentGroup = assignmentGroups.findBy('id', as.assignment_group_id)
      set as, 'sortable_name', as.name.toLowerCase()
      set as, 'ag_position', assignmentGroup.position
      set as, 'noPointsPossibleWarning', assignmentGroup.invalid

      @updateEffectiveDueDatesOnAssignment(as)

      if as.due_at
        due_at = tz.parse(as.due_at)
        set as, 'due_at', due_at
        set as, 'sortable_date', +due_at / 1000
      else
        set as, 'sortable_date', Number.MAX_VALUE

    differentiatedAssignmentVisibleToStudent: (assignment, student_id) ->
      return false unless assignment?
      return true unless assignment.only_visible_to_overrides
      _.include(assignment.assignment_visibility, student_id)

    studentsThatCanSeeAssignment: (assignment) ->
      students = @studentsHash()
      return students unless assignment?.only_visible_to_overrides
      assignment.assignment_visibility.reduce( (result, id) ->
        result[id] = students[id]
        result
      ,{})

    checkForNoPointsWarning: (ag) ->
      pointsPossible = _.inject ag.assignments
      , ((sum, a) -> sum + (a.points_possible || 0))
      , 0
      pointsPossible == 0

    checkForInvalidGroups: (->
      @get('assignment_groups').forEach (ag) =>
        set ag, "invalid", @checkForNoPointsWarning(ag)
    ).observes('assignment_groups.@each')

    invalidAssignmentGroups: (->
      @get('assignment_groups').filterProperty('invalid',true)
    ).property('assignment_groups.@each.invalid')

    showInvalidGroupWarning: (->
      @get("invalidAssignmentGroups").length > 0 && @get('weightingScheme') == "percent"
    ).property("invalidAssignmentGroups", "weightingScheme")

    invalidGroupNames: (->
      names = @get("invalidAssignmentGroups").map (group) ->
        group.name
    ).property("invalidAssignmentGroups").readOnly()

    invalidGroupsWarningPhrases:(->
      I18n.t("invalid_group_warning",
        {one: "Note: Score does not include assignments from the group %{list_of_group_names} because it has no points possible.",
        other:"Note: Score does not include assignments from the groups %{list_of_group_names} because they have no points possible."}
        {count: @get('invalidGroupNames').length, list_of_group_names: @get('invalidGroupNames').join(" or ")})
    ).property('invalidGroupNames')

    populateAssignmentsFromGroups: (->
      return unless @get('assignment_groups.isLoaded') and !@get('assignment_groups.isLoading')
      assignmentGroups = @get('assignment_groups')
      assignments = _.flatten(assignmentGroups.mapBy 'assignments')
      assignmentList = []
      assignments.forEach (as) =>
        @processAssignment(as, assignmentGroups)
        shouldRemoveAssignment = (as.published is false) or
          as.submission_types.contains 'not_graded' or
          as.submission_types.contains 'attendance' and !@get('showAttendance')
        if shouldRemoveAssignment
          assignmentGroups.findBy('id', as.assignment_group_id).assignments.removeObject as
        else
          assignmentList.push(as)
      @get('assignmentsFromGroups').setProperties(content: assignmentList, isLoaded: true)
    ).observes('assignment_groups.isLoaded', 'assignment_groups.isLoading')

    populateAssignments: (->
      assignmentsFromGroups = @get('assignmentsFromGroups.content')
      selectedStudent = @get('selectedStudent')
      submissionStateMap = @get('submissionStateMap')

      proxy = Ember.ArrayProxy.createWithMixins(
        Ember.SortableMixin, { content: [] }
      )

      if selectedStudent?
        assignmentsFromGroups.forEach (assignment) =>
          submissionCriteria = { assignment_id: assignment.id, user_id: selectedStudent.id }
          unless submissionStateMap?.getSubmissionState(submissionCriteria)?.hideGrade
            proxy.addObject(assignment)
      else
        proxy.addObjects(assignmentsFromGroups)

      proxy.set('sortProperties', @get('assignments.sortProperties'))
      @set('assignments', proxy)
    ).observes('assignmentsFromGroups.isLoaded', 'selectedStudent')

    populateSubmissionStateMap: (->
      map = new SubmissionStateMap(
        hasGradingPeriods: !!@has_grading_periods
        selectedGradingPeriodID: @get('selectedGradingPeriod.id') || '0'
        isAdmin: ENV.current_user_roles && _.contains(ENV.current_user_roles, "admin")
      )
      map.setup(@get('students').toArray(), @get('assignmentsFromGroups.content').toArray())
      @set('submissionStateMap', map)
    ).observes('enrollments.isLoaded', 'assignmentsFromGroups.isLoaded', 'submissions.content.length')

    includeUngradedAssignments: (->
      userSettings.contextGet('include_ungraded_assignments') or false
    ).property().volatile()

    showAttendance: (->
      userSettings.contextGet 'show_attendance'
    ).property().volatile()

    updateUngradedAssignmentUserSetting: ( ->
      isChecked = @get('includeUngradedAssignments')
      if isChecked?
        userSettings.contextSet 'include_ungraded_assignments', isChecked
    ).observes('includeUngradedAssignments')

    assignmentGroupsHash: ->
      ags = {}
      return ags unless @get('assignment_groups')
      @get('assignment_groups').forEach (ag) ->
        ags[ag.id] = ag
      ags

    assignmentSortOptions:
      [
        {
          label: I18n.t "assignment_order_assignment_groups", "By Assignment Group and Position"
          value: "assignment_group"
        }
        {
          label: I18n.t "assignment_order_alpha", "Alphabetically"
          value: "alpha"
        }
        {
          label: I18n.t "assignment_order_due_date", "By Due Date"
          value: "due_date"
        }
      ]

    assignmentSort: ((key, value) ->
      savedSortType = userSettings.contextGet('sort_grade_columns_by')
      savedSortOption = @get('assignmentSortOptions').findBy('value', savedSortType?.sortType)
      if value
        userSettings.contextSet('sort_grade_columns_by', {sortType: value.value})
        value
      else if savedSortOption?
        savedSortOption
      else
        # default to assignment group, but don't change saved setting
        @get('assignmentSortOptions').findBy('value', 'assignment_group')
    ).property()

    sortAssignments: (->
      sort = @get('assignmentSort')
      return unless sort
      sort_props = switch sort.value
        when 'assignment_group', 'custom' then ['ag_position', 'position']
        when 'alpha' then ['sortable_name']
        when 'due_date' then ['sortable_date', 'sortable_name']
        else ['ag_position', 'position']
      @get('assignments').set('sortProperties', sort_props)
    ).observes('assignmentSort').on('init')

    updateAssignmentStatusInGradingPeriod: (->
      assignment = @get('selectedAssignment')

      unless assignment
        @set('assignmentInClosedGradingPeriod', null)
        @set('disableAssignmentGrading', null)
        return

      @set('assignmentInClosedGradingPeriod', assignment.inClosedGradingPeriod)

      # Calculate whether the current user is able to grade assignments given their role and the
      # result of the calculations above
      if ENV.current_user_roles? && _.contains(ENV.current_user_roles, 'admin')
        @set('disableAssignmentGrading', false)
      else
        @set('disableAssignmentGrading', assignment.inClosedGradingPeriod)
    ).observes('selectedAssignment')

    selectedSubmission: ((key, selectedSubmission) ->
      if arguments.length > 1
        @set 'selectedStudent', @get('students').findBy('id', selectedSubmission.user_id)
        @set 'selectedAssignment', @get('assignments').findBy('id', selectedSubmission.assignment_id)
      else
        return null unless @get('selectedStudent')? and @get('selectedAssignment')?
        student = @get 'selectedStudent'
        assignment = @get 'selectedAssignment'
        sub = get student, "assignment_#{assignment.id}"
        selectedSubmission = sub or {
          user_id: student.id
          assignment_id: assignment.id
          hidden: !@differentiatedAssignmentVisibleToStudent(assignment, student.id)
          grade_matches_current_submission: true
        }
      submissionState = @submissionStateMap?.getSubmissionState(selectedSubmission) || {}
      selectedSubmission.gradeLocked = submissionState.locked
      selectedSubmission
    ).property('selectedStudent', 'selectedAssignment')

    selectedSubmissionHidden: (->
      @get('selectedSubmission.hidden') || false
    ).property('selectedStudent', 'selectedAssignment')

    selectedSubmissionLate: (->
      ( @get('selectedSubmission.points_deducted') || 0 ) > 0
    ).property('selectedStudent', 'selectedAssignment')

    selectedOutcomeResult: ( ->
      return null unless @get('selectedStudent')? and @get('selectedOutcome')?
      student = @get 'selectedStudent'
      outcome = @get 'selectedOutcome'
      result = @get('outcome_rollups').find (x) ->
        x.user_id == student.id && x.outcome_id == outcome.id
      result.mastery_points = round(outcome.mastery_points, 2) if result
      result or {
        user_id: student.id
        outcome_id: outcome.id
      }
    ).property('selectedStudent', 'selectedOutcome')

    outcomeResultIsDefined: ( ->
      @get('selectedOutcomeResult')?.score?
    ).property('selectedOutcomeResult')

    showAssignmentPointsWarning: (->
      @get("selectedAssignment.noPointsPossibleWarning") and @get('groupsAreWeighted')
    ).property('selectedAssignment', 'groupsAreWeighted')

    selectedStudentSections: (->
      student = @get('selectedStudent')
      sections = @get('sections')
      return null unless sections.isLoaded and student?
      sectionNames = student.sections.map (id) -> sections.findBy('id', id).name
      sectionNames.join(', ')
    ).property('selectedStudent', 'sections.isLoaded')

    assignmentDetails: (->
      return null unless @get('selectedAssignment')?
      {locals} = AssignmentDetailsDialog::compute.call AssignmentDetailsDialog::, {
        students: @studentsHash()
        assignment: @get('selectedAssignment')
      }
      locals
    ).property('selectedAssignment', 'students.@each.total_grade')

    outcomeDetails: (->
      return null unless @get('selectedOutcome')?
      rollups = @get('outcome_rollups').filterBy('outcome_id', @get('selectedOutcome').id)
      scores = _.filter(_.pluck(rollups, 'score'), _.isNumber)
      details =
        average: outcomeGrid.Math.mean(scores)
        max: outcomeGrid.Math.max(scores)
        min: outcomeGrid.Math.min(scores)
        cnt: outcomeGrid.Math.cnt(scores)
    ).property('selectedOutcome', 'outcome_rollups')

    calculationDetails: (->
      return null unless @get('selectedOutcome')?
      outcome = @get('selectedOutcome')
      _.extend({
        calculation_method: outcome.calculation_method
        calculation_int: outcome.calculation_int
      }, new CalculationMethodContent(outcome).present())
    ).property('selectedOutcome')

    assignmentSubmissionTypes: (->
      types = @get('selectedAssignment.submission_types')
      submissionTypes = @get('submissionTypes')
      if types == undefined || types.length == 0
        submissionTypes['none']
      else if types.length == 1
        submissionTypes[types[0]]
      else
        result = []
        types.forEach (type) -> result.push(submissionTypes[type])
        result.join(', ')
    ).property('selectedAssignment')

    submissionTypes: {
      'discussion_topic': I18n.t 'discussion_topic', 'Discussion topic'
      'online_quiz': I18n.t 'online_quiz', 'Online quiz'
      'on_paper': I18n.t 'on_paper', 'On paper'
      'none': I18n.t 'none', 'None'
      'external_tool': I18n.t 'external_tool', 'External tool'
      'online_text_entry': I18n.t 'online_text_entry', 'Online text entry'
      'online_url': I18n.t 'online_url', 'Online URL'
      'online_upload': I18n.t 'online_upload', 'Online upload'
      'media_recording': I18n.t 'media_recordin', 'Media recording'
    }

    assignmentIndex: (->
      selected = @get('selectedAssignment')
      if selected then @get('assignments').indexOf(selected) else -1
    ).property('selectedAssignment', 'assignmentSort')

    studentIndex: (->
      selected = @get('selectedStudent')
      if selected then @get('studentsInSelectedSection').indexOf(selected) else -1
    ).property('selectedStudent', 'selectedSection')

    outcomeIndex: (->
      selected = @get('selectedOutcome')
      if selected then @get('outcomes').indexOf(selected) else -1
    ).property('selectedOutcome')

    displayName: (->
      if @get('hideStudentNames')
        "hiddenName"
      else if ENV.GRADEBOOK_OPTIONS.list_students_by_sortable_name_enabled
        "sortable_name"
      else
        "name"
    ).property('hideStudentNames')

    fetchCorrectEnrollments: (->
      return if (@get('enrollments.isLoading'))
      if @get('showConcludedEnrollments')
        url = ENV.GRADEBOOK_OPTIONS.enrollments_with_concluded_url
      else
        url = ENV.GRADEBOOK_OPTIONS.enrollments_url

      enrollments = @get('enrollments')
      enrollments.clear()
      fetchAllPages(url, records: enrollments)
    ).observes('showConcludedEnrollments')

    omitFromFinalGrade: (->
      @get('selectedAssignment.omit_from_final_grade')
    ).property('selectedAssignment')
