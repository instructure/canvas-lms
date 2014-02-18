define [
  'compiled/userSettings'
  '../../shared/xhr/fetch_all_pages'
  'i18n!sr_gradebook'
  'ember'
  'underscore'
  'compiled/AssignmentDetailsDialog'
  'compiled/AssignmentMuter'
  ], (userSettings, fetchAllPages, I18n, Ember, _,  AssignmentDetailsDialog, AssignmentMuter ) ->

  {get, set} = Ember

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
        array
    args.push options
    Ember.arrayComputed.apply(null, args)

  ScreenreaderGradebookController = Ember.ObjectController.extend

    downloadUrl: "#{get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')}/gradebook.csv"
    gradingHistoryUrl: "#{get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')}/history"
    hideStudentNames: false

    actions:
      selectItem: (property, goTo) ->
        list = @getListFor(property)
        currentIndex = list.indexOf(@get(property))
        item = list.objectAt(currentIndex - 1) if goTo == 'previous'
        item = list.objectAt(currentIndex + 1) if goTo == 'next'
        @set(property, item)

    setupSubmissionCallback: (->
      $.subscribe 'submissions_updated', _.bind(@updateSubmissionsFromExternal, this)
    ).on('init')

    willDestroy: ->
      $.unsubscribe 'submissions_updated'
      @_super()

    updateSubmissionsFromExternal: (submissions)->
      students = @get('students')
      subs_proxy = @get('submissions')
      selected = @get('selectedSubmission')
      submissions.forEach (submission) =>
        submissionsForStudent = subs_proxy.findBy('user_id', submission.user_id)
        oldSubmission = submissionsForStudent.submissions.findBy('assignment_id', submission.assignment_id)

        submissionsForStudent.submissions.removeObject oldSubmission
        submissionsForStudent.submissions.addObject submission
        @updateSubmission submission, students.findBy('id', submission.user_id)
        if selected and selected.assignment_id == submission.assignment_id and selected.user_id == submission.user_id
          @set('selectedSubmission', submission)

    sectionSelectDefaultLabel: I18n.t "all_sections", "All Sections"
    studentSelectDefaultLabel: I18n.t "no_student", "No Student Selected"
    assignmentSelectDefaultLabel: I18n.t "no_assignment", "No Assignment Selected"

    students: studentsUniqByEnrollments('enrollments')

    studentsHash: ->
      students = {}
      @get('students').forEach (s) ->
        students[s.id] = s
      students

    # properties that get set by fast select on the controller
    #selectedStudent
    #selectedSection
    #selectedAssignment

    studentGrades: (->
      selected = @get('selectedStudent')
      return null if not selected
      #will always find the first one, but this should be OK
      enrollment = @get('enrollments').findBy('user_id', selected.id)
      enrollment.grades
    ).property('selectedStudent')

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
        submission.submissions.forEach ((s) ->
          @updateSubmission(s, student)
        ), this
        set(student, 'isLoading', false)
        set(student, 'isLoaded', true)
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

    populateAssignments: (->
      assignment_groups = @get('assignment_groups')
      assignments = _.flatten(assignment_groups.mapBy 'assignments')
      assignment_proxy =  @get('assignments')
      assignments.forEach (as) =>
        return if assignment_proxy.findBy('id', as.id)
        set as, 'sortable_name', as.name.toLowerCase()
        set as, 'ag_position', assignment_groups.findBy('id', as.assignment_group_id).position
        if as.due_at
          set as, 'due_at', $.parseFromISO(as.due_at)
          set as, 'sortable_date', as.due_at.timestamp
        else
          set as, 'sortable_date', Number.MAX_VALUE

        assignment_proxy.pushObject as unless (@isDraftState() and as.published is false) or
                                              as.submission_types.contains 'not_graded' or
                                              as.submission_types.contains 'attendance' and !@get('showAttendance')
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
        when 'due_date' then ['sortable_date']

      @get('assignments').set('sortProperties', sort_props)

    ).observes('assignmentSort')

    selectedSubmission: (->
      return null unless @get('selectedStudent')? and @get('selectedAssignment')?
      student = @get 'selectedStudent'
      assignment = @get 'selectedAssignment'
      sub = get student, "assignment_#{assignment.id}"
      sub or {
        user_id: student.id
        assignment_id: assignment.id
      }
    ).property('selectedStudent', 'selectedAssignment')

    selectedSubmissionGrade: (->
      @get('selectedSubmission')?.grade or '-'
    ).property('selectedSubmission')

    assignmentDetails: (->
      return null unless @get('selectedAssignment')?
      {locals} = AssignmentDetailsDialog::compute.call AssignmentDetailsDialog::, {
        students: @studentsHash()
        assignment: @get('selectedAssignment')
      }
      locals
    ).property('selectedAssignment')

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
