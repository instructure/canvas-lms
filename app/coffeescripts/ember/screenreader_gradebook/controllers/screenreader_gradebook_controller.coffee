define [
  'compiled/util/round'
  'compiled/userSettings'
  '../../shared/xhr/fetch_all_pages'
  'i18n!sr_gradebook'
  'ember'
  'underscore'
  'compiled/AssignmentDetailsDialog'
  'compiled/AssignmentMuter'
  'compiled/grade_calculator'
  ], (round, userSettings, fetchAllPages, I18n, Ember, _,  AssignmentDetailsDialog, AssignmentMuter, GradeCalculator ) ->

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

  ScreenreaderGradebookController = Ember.ObjectController.extend

    downloadUrl: "#{get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')}/gradebook.csv"
    gradingHistoryUrl: "#{get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')}/history"
    hideStudentNames: false
    showConcludedEnrollments: false

    selectedStudent: null

    selectedSection: null

    selectedAssignment: null

    weightingScheme: null

    actions:

      gradeUpdated: (submissions) ->
        @updateSubmissionsFromExternal submissions

      selectItem: (property, goTo) ->
        list = @getListFor(property)
        currentIndex = list.indexOf(@get(property))
        item = list.objectAt(currentIndex - 1) if goTo == 'previous'
        item = list.objectAt(currentIndex + 1) if goTo == 'next'
        @set(property, item)

    setupSubmissionCallback: (->
      $.subscribe 'submissions_updated', _.bind(@updateSubmissionsFromExternal, this)
    ).on('init')

    setupAssignmentGroupsChange: (->
      $.subscribe 'assignment_group_weights_changed', _.bind(@checkWeightingScheme, this)
      @set 'weightingScheme', ENV.GRADEBOOK_OPTIONS.group_weighting_scheme
    ).on('init')

    willDestroy: ->
      $.unsubscribe 'submissions_updated'
      $.unsubscribe 'assignment_group_weights_changed'
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
    ).observes('includeUngradedAssignments')

    sectionSelectDefaultLabel: I18n.t "all_sections", "All Sections"
    studentSelectDefaultLabel: I18n.t "no_student", "No Student Selected"
    assignmentSelectDefaultLabel: I18n.t "no_assignment", "No Assignment Selected"

    students: studentsUniqByEnrollments('enrollments')

    studentsHash: ->
      students = {}
      @get('students').forEach (s) ->
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
        fetchAllPages(ENV.GRADEBOOK_OPTIONS.submissions_url, student_ids: student_ids,  @get('submissions'))
    ).observes('students.@each').on('init')

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
          set(student, 'isLoading', false)
          set(student, 'isLoaded', true)
          @calculateStudentGrade student
      ), this
    ).observes('submissions.@each')

    updateSubmission: (submission, student) ->
      submission.submitted_at = $.parseFromISO(submission.submitted_at) if submission.submitted_at
      set(student, "assignment_#{submission.assignment_id}", submission)

    assignments: Ember.ArrayProxy.createWithMixins(Ember.SortableMixin,
        content: []
        sortProperties: ['ag_position', 'position']
      )

    isDraftState: ->
      ENV.GRADEBOOK_OPTIONS.draft_state_enabled

    processAssignment: (as, assignmentGroups) ->
      set as, 'sortable_name', as.name.toLowerCase()
      set as, 'ag_position', assignmentGroups.findBy('id', as.assignment_group_id).position
      if as.due_at
        set as, 'due_at', $.parseFromISO(as.due_at)
        set as, 'sortable_date', as.due_at.timestamp
      else
        set as, 'sortable_date', Number.MAX_VALUE

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
          assignmentsProxy.pushObject as
    ).observes('assignment_groups.@each')

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

    sortAssignments: (->
      sort = @get('assignmentSort')
      return unless sort
      sort_props = switch sort.value
        when 'assignment_group' then ['ag_position', 'position']
        when 'alpha' then ['sortable_name']
        when 'due_date' then ['sortable_date', 'sortable_name']

      @get('assignments').set('sortProperties', sort_props)

    ).observes('assignmentSort')

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

    # Next/Previous Student/Assignment

    getListFor: (property) ->
      return @get('studentsInSelectedSection') if property == 'selectedStudent'
      return @get('assignments') if property == 'selectedAssignment'

    assignmentIndex: (->
      selected = @get('selectedAssignment')
      if selected then @get('assignments').indexOf(selected) else -1
    ).property('selectedAssignment', 'assignmentSort')

    studentIndex: (->
      selected = @get('selectedStudent')
      if selected then @get('studentsInSelectedSection').indexOf(selected) else -1
    ).property('selectedStudent', 'selectedSection')

    disablePrevAssignmentButton: Ember.computed.lte('assignmentIndex', 0)
    disablePrevStudentButton: Ember.computed.lte('studentIndex', 0)

    disableNextAssignmentButton: (->
      next = @get('assignments').objectAt(@get('assignmentIndex') + 1)
      !(@get('assignments.length') and next)
    ).property('selectedAssignment', 'assignments.@each')

    disableNextStudentButton: (->
      next = @get('studentsInSelectedSection').objectAt(@get('studentIndex') + 1)
      !(@get('studentsInSelectedSection.length') and next)
    ).property('selectedStudent', 'studentsInSelectedSection', 'selectedSection')

    ariaDisabledPrevAssignment: (->
      new Boolean(@get('disablePrevAssignmentButton'))?.toString()
    ).property('disablePrevAssignmentButton')

    ariaDisabledPrevStudent: (->
      new Boolean(@get('disablePrevStudentButton'))?.toString()
    ).property('disablePrevStudentButton')

    ariaDisabledNextAssignment: (->
      new Boolean(@get('disableNextAssignmentButton'))?.toString()
    ).property('disableNextAssignmentButton')

    ariaDisabledNextStudent: (->
      new Boolean(@get('disableNextStudentButton'))?.toString()
    ).property('disableNextStudentButton')

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
      fetchAllPages(url, null, enrollments)
    ).observes('showConcludedEnrollments')
