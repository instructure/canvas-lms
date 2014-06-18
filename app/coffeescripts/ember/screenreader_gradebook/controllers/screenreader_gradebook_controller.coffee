define [
  'ic-ajax'
  'compiled/util/round'
  'compiled/userSettings'
  '../../shared/xhr/fetch_all_pages'
  '../../shared/xhr/parse_link_header'
  'i18n!sr_gradebook'
  'ember'
  'underscore'
  'timezone'
  'compiled/AssignmentDetailsDialog'
  'compiled/AssignmentMuter'
  'compiled/grade_calculator'
  'compiled/gradebook2/OutcomeGradebookGrid'
  '../../shared/components/ic_submission_download_dialog_component'
  ], (ajax, round, userSettings, fetchAllPages, parseLinkHeader, I18n, Ember, _, tz, AssignmentDetailsDialog, AssignmentMuter, GradeCalculator, outcomeGrid, ic_submission_download_dialog ) ->

  {get, set, setProperties} = Ember

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html


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

    errors: (->
      # this is a sad, sad hack
      # until we can get flash notifications working app-wide for screenreaders
      if Ember.$('#flash_message_holder li').size() > 0
        close = Ember.$('#flash_message_holder li a').text().trim()
        message = Ember.$('#flash_message_holder li').text().replace(close,'').trim()
        node = Ember.$("<span role='alert'>#{message}</span>")
        Ember.$(node).appendTo(Ember.$('#flash_screenreader_holder'))
    ).on('init')

    contextUrl: contextUrl

    downloadCsvUrl: "#{contextUrl}/gradebook.csv"

    downloadOutcomeCsvUrl: "#{contextUrl}/outcome_rollups.csv"

    gradingHistoryUrl:"#{contextUrl}/gradebook/history"

    speedGraderUrl: (->
      "#{contextUrl}/gradebook/speed_grader?assignment_id=#{@get('selectedAssignment.id')}"
    ).property('selectedAssignment')

    studentUrl: (->
      "#{contextUrl}/grades/#{@get('selectedStudent.id')}"
    ).property('selectedStudent')

    showTotalAsPoints: (->
      ENV.GRADEBOOK_OPTIONS.show_total_grade_as_points
    ).property()

    changeGradebookVersionUrl: (->
      "#{get(window, 'ENV.GRADEBOOK_OPTIONS.change_gradebook_version_url')}"
    ).property()

    hideOutcomes: (->
      !get(window, 'ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled')
    ).property()

    showDownloadSubmissionsButton: (->
      @get('selectedAssignment.has_submitted_submissions') and
      _.intersection(@get('selectedAssignment.submission_types'), ['online_upload','online_text_entry','online_url']) != []
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

    selectedStudent: null

    selectedSection: null

    selectedAssignment: null

    weightingScheme: null

    ariaAnnounced: null

    actions:

      columnUpdated: (columnData, columnID) ->
        @updateColumnData columnData, columnID

      gradeUpdated: (submissions) ->
        @updateSubmissionsFromExternal submissions

      selectItem: (property, goTo) ->
        list = @getList(property)
        currentIndex = list.indexOf(@get(property))

        if goTo == 'previous'
          item = list.objectAt(currentIndex - 1)
          unless list.objectAt(currentIndex - 2)
            $("#next_#{@getButton(property)}").focus()
        if goTo == 'next'
          item = list.objectAt(currentIndex + 1)
          unless list.objectAt(currentIndex + 2)
            $("#prev_#{@getButton(property)}").focus()

        @announce property, item
        @set property, item

    announce: (prop, item) ->
      Ember.run.next =>
        if prop is 'selectedStudent' and @get('hideStudentNames')
          text_to_announce = get item, 'hiddenName'
        else if prop is 'selectedOutcome'
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

    setupAssignmentGroupsChange: (->
      Ember.$.subscribe 'assignment_group_weights_changed', _.bind(@checkWeightingScheme, this)
      @set 'weightingScheme', ENV.GRADEBOOK_OPTIONS.group_weighting_scheme
    ).on('init')

    willDestroy: ->
      Ember.$.unsubscribe 'submissions_updated'
      Ember.$.unsubscribe 'assignment_group_weights_changed'
      @_super()

    checkWeightingScheme: ({assignmentGroups})->
      ags = @get('assignment_groups')
      ags.clear()
      ags.pushObjects assignmentGroups

      @set 'weightingScheme', ENV.GRADEBOOK_OPTIONS.group_weighting_scheme

    updateSubmissionsFromExternal: (submissions) ->
      students = @get('students')
      subs_proxy = @get('submissions')
      selected = @get('selectedSubmission')
      submissions.forEach (submission) =>
        submissionsForStudent = subs_proxy.findBy('user_id', submission.user_id)
        oldSubmission = submissionsForStudent.submissions.findBy('assignment_id', submission.assignment_id)

        submissionsForStudent.submissions.removeObject oldSubmission
        submissionsForStudent.submissions.addObject submission
        student = students.findBy('id', submission.user_id)
        @updateSubmission submission, student
        @calculateStudentGrade student
        if selected and selected.assignment_id == submission.assignment_id and selected.user_id == submission.user_id
          set(this, 'selectedSubmission', submission)

    calculate: (submissionsArray) ->
      GradeCalculator.calculate submissionsArray, @assignmentGroupsHash(), @get('weightingScheme')

    calculateStudentGrade: (student) ->
      if student.isLoaded
        finalOrCurrent = if @get('includeUngradedAssignments') then 'final' else 'current'
        submissionsAsArray = (value for key, value of student when key.match /^assignment_(?!group)/)
        result = @calculate(submissionsAsArray)
        for group in result.group_sums
          set(student, "assignment_group_#{group.group.id}", group[finalOrCurrent])
          for submissionData in group[finalOrCurrent].submissions
            set(submissionData.submission, 'drop', submissionData.drop)
        result = result[finalOrCurrent]

        percent = round (result.score / result.possible * 100), 1
        percent = 0 if isNaN(percent)
        setProperties student,
          total_grade: result
          total_percent: percent

    calculateAllGrades: (->
      @get('students').forEach (student) => @calculateStudentGrade student
    ).observes('includeUngradedAssignments','groupsAreWeighted', 'assignment_groups.@each.group_weight')

    setFinalGradeDisplay: (->
      @get('students').forEach (student) =>
        set(student, "final_grade_point_ratio", @pointRatioDisplay(student, @get('groupsAreWeighted')))
        if @get('showLetterGrades')
          set(student, "final_letter_grade", GradeCalculator.letter_grade(ENV.GRADEBOOK_OPTIONS.grading_standard, student.total_percent))
    ).observes('students.@each.total_grade','groupsAreWeighted')

    pointRatioDisplay: (student, weighted_groups) ->
      if weighted_groups or not student.total_grade
        null
      else
        "#{student.total_grade.score} / #{student.total_grade.possible}"

    sectionSelectDefaultLabel: I18n.t "all_sections", "All Sections"
    studentSelectDefaultLabel: I18n.t "no_student", "No Student Selected"
    assignmentSelectDefaultLabel: I18n.t "no_assignment", "No Assignment Selected"
    outcomeSelectDefaultLabel: I18n.t "no_outcome", "No Outcome Selected"

    students: studentsUniqByEnrollments('enrollments')

    studentsHash: ->
      students = {}
      @get('students').forEach (s) ->
        unless s.role == "StudentViewEnrollment"
          students[s.id] = s
      students

    fetchStudentSubmissions: (->
      Ember.run.once =>
        notYetLoaded = @get('students').filter (student) ->
          return false if get(student, 'isLoaded') or get(student, 'isLoading')
          set(student, 'isLoading', true)
          student

        return unless notYetLoaded.length
        student_ids = notYetLoaded.mapBy('id')
        fetchAllPages(ENV.GRADEBOOK_OPTIONS.submissions_url, records: @get('submissions'), data: student_ids: student_ids)
    ).observes('students.@each').on('init')

    publishToSisEnabled: (->
      ENV.GRADEBOOK_OPTIONS.publish_to_sis_enabled
    ).property()

    publishToSisURL:(->
      ENV.GRADEBOOK_OPTIONS.publish_to_sis_url
    ).property()

    showLetterGrades:(->
      !!ENV.GRADEBOOK_OPTIONS.grading_standard
    ).property()

    teacherNotes: (->
      ENV.GRADEBOOK_OPTIONS.teacher_notes
    ).property().volatile()

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
        ENV.GRADEBOOK_OPTIONS.custom_columns_url
      else
        notesID = @get('teacherNotes')?.id
        ENV.GRADEBOOK_OPTIONS.custom_column_url.replace(/:id/, notesID)
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
      ajax(
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
        ajax(
          url: ENV.GRADEBOOK_OPTIONS.reorder_custom_columns_url
          type:"POST"
          data:
            order: customColumns.mapBy('id')
        )

    displayPointTotals: (->
      if @get("groupsAreWeighted")
        false
      else
        @get("showTotalAsPoints")
    ).property('groupsAreWeighted', 'showTotalAsPoints')

    groupsAreWeighted: (->
      @get("weightingScheme") == "percent"
    ).property("weightingScheme")

    updateShowTotalAs: (->
      @set "showTotalAsPoints", @get("displayPointTotals")
      ajax(
        dataType: "json"
        type: "PUT"
        url: ENV.GRADEBOOK_OPTIONS.setting_update_url
        data:
          show_total_grade_as_points: @get("displayPointTotals"))
    ).observes('showTotalAsPoints', 'groupsAreWeighted')

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

    submissionsLoaded: (->
      submissions = @get('submissions')
      submissions.forEach ((submission) ->
        student = @get('students').findBy('id', submission.user_id)
        if student?
          submission.submissions.forEach ((s) ->
            @updateSubmission(s, student)
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

    assignments: Ember.ArrayProxy.createWithMixins(Ember.SortableMixin,
        content: []
        sortProperties: ['ag_position', 'position']
      )

    isDraftState: ->
      ENV.GRADEBOOK_OPTIONS.draft_state_enabled

    processAssignment: (as, assignmentGroups) ->
      assignmentGroup = assignmentGroups.findBy('id', as.assignment_group_id)
      set as, 'sortable_name', as.name.toLowerCase()
      set as, 'ag_position', assignmentGroup.position
      set as, 'noPointsPossibleWarning', assignmentGroup.invalid
      if as.due_at
        due_at = tz.parse(as.due_at)
        set as, 'due_at', due_at
        set as, 'sortable_date', +due_at / 1000
      else
        set as, 'sortable_date', Number.MAX_VALUE

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

    populateAssignments: (->
      assignmentGroups = @get('assignment_groups')
      assignments = _.flatten(assignmentGroups.mapBy 'assignments')
      assignmentsProxy =  @get('assignments')
      assignments.forEach (as) =>
        return if assignmentsProxy.findBy('id', as.id)
        @processAssignment(as, assignmentGroups)

        shouldRemoveAssignment = (@isDraftState() and as.published is false) or
          as.submission_types.contains 'not_graded' or
          as.submission_types.contains 'attendance' and !@get('showAttendance')
        if shouldRemoveAssignment
          assignmentGroups.findBy('id', as.assignment_group_id).assignments.removeObject as
        else
          assignmentsProxy.addObject as
    ).observes('assignment_groups', 'assignment_groups.@each')

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

    selectedSubmission: ((key, selectedSubmission) ->
      if arguments.length > 1
        @set 'selectedStudent', @get('students').findBy('id', selectedSubmission.user_id)
        @set 'selectedAssignment', @get('assignments').findBy('id', selectedSubmission.assignment_id)
        selectedSubmission
      else
        return null unless @get('selectedStudent')? and @get('selectedAssignment')?
        student = @get 'selectedStudent'
        assignment = @get 'selectedAssignment'
        sub = get student, "assignment_#{assignment.id}"
        sub or {
          user_id: student.id
          assignment_id: assignment.id
        }
    ).property('selectedStudent', 'selectedAssignment')

    selectedOutcomeResult: ( ->
      return null unless @get('selectedStudent')? and @get('selectedOutcome')?
      student = @get 'selectedStudent'
      outcome = @get 'selectedOutcome'
      result = @get('outcome_rollups').find (x) ->
        x.user_id == student.id && x.outcome_id == outcome.id
      result or {
        user_id: student.id
        outcome_id: outcome.id
      }
    ).property('selectedStudent', 'selectedOutcome')

    outcomeResultIsDefined: ( ->
      @get('selectedOutcomeResult').score?
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

    # Next/Previous Student/Assignment

    getList: (property) ->
      return @get('studentsInSelectedSection') if property == 'selectedStudent'
      return @get('assignments') if property == 'selectedAssignment'
      return @get('outcomes') if property == 'selectedOutcome'

    getButton: (property) ->
      return 'student' if property == 'selectedStudent'
      return 'assignment' if property == 'selectedAssignment'

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

    disablePrevAssignmentButton: Ember.computed.lte('assignmentIndex', 0)
    disablePrevStudentButton: Ember.computed.lte('studentIndex', 0)
    disablePrevOutcomeButton: Ember.computed.lte('outcomeIndex', 0)

    disableNextAssignmentButton: (->
      next = @get('assignments').objectAt(@get('assignmentIndex') + 1)
      !(@get('assignments.length') and next)
    ).property('selectedAssignment', 'assignments.@each')

    disableNextStudentButton: (->
      next = @get('studentsInSelectedSection').objectAt(@get('studentIndex') + 1)
      !(@get('studentsInSelectedSection.length') and next)
    ).property('selectedStudent', 'studentsInSelectedSection', 'selectedSection')

    disableNextOutcomeButton: (->
      next = @get('outcomes').objectAt(@get('outcomeIndex') + 1)
      !(@get('outcomes.length') and next)
    ).property('selectedOutcome', 'outcomes.@each')

    displayName: (->
      if @get('hideStudentNames')
        "hiddenName"
      else
        "name"
    ).property('hideStudentNames')

    fetchCorrectEnrollments: (->
      if @get('showConcludedEnrollments')
        url = ENV.GRADEBOOK_OPTIONS.students_url_with_concluded_enrollments
      else
        url = ENV.GRADEBOOK_OPTIONS.students_url

      enrollments = @get('enrollments')
      enrollments.clear()
      fetchAllPages(url, records: enrollments)
    ).observes('showConcludedEnrollments')
