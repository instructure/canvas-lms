define [
  'i18n!sr_gradebook'
  'ember'
  'underscore'
  'compiled/AssignmentDetailsDialog'
  'compiled/AssignmentMuter'
  ], (I18n, Ember, _,  AssignmentDetailsDialog, AssignmentMuter ) ->

  {get} = Ember

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  studentsUniqByEnrollments = (args...)->
    options =
      initialize: (array, changeMeta, instanceMeta) ->
        instanceMeta.students = {}
      addedItem: (array, enrollment, changeMeta, iMeta) ->
        student = enrollment.user
        student.sections ||= []
        student.sections = Ember.A(student.sections)
        student.sections.push(enrollment.course_section_id)
        return array if iMeta.students[student.id]
        iMeta.students[student.id] = student.id
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
    gradingHistoryUrl:  "#{get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')}/history"

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
        submissionsForStudent = subs_proxy.findBy('user_id', submission.user_id).submissions
        oldSubmission = submissionsForStudent.find (sub) ->
          submission.assignment_id == sub.assignment_id

        submissionsForStudent.removeObject oldSubmission
        submissionsForStudent.addObject submission
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
      selected = @get('selectedStudent').enrollment.grades
    ).property('selectedStudent')

    submissionsLoaded: (->
      submissions = @get('submissions')
      submissions.forEach ((submission) ->
        student = @get('students').findBy('id', submission.user_id)
        Ember.set(student, 'isLoaded', true)
      ), this
    ).observes('submissions.@each')

    updateSubmission: (submission, student) ->
      submission.submitted_at = $.parseFromISO(submission.submitted_at) if submission.submitted_at
      student["assignment_#{submission.assignment_id}"] = submission

    studentLoadedObserver: (->
      @get('students').filterBy('isLoaded', true).forEach (student) =>
        @get('submissions').findBy('user_id', student.id).submissions?.forEach ((submission) ->
          return if student["assignment_#{submission.assignment_id}"]
          @updateSubmission(submission, student)
        ), this
    ).observes('students.@each.isLoaded')

    assignments: (->
      _.flatten(@get('assignment_groups').map (ag) -> ag.assignments)
    ).property('assignment_groups.@each')

    assignmentGroupsHash: ->
      ags = {}
      @get('assignment_groups').forEach (ag) ->
        ags[ag.id] = ag
      ags

    selectedSubmission: (->
      return null unless @get('selectedStudent')? and @get('selectedAssignment')?
      student = @get 'selectedStudent'
      sub = @get('submissions').findBy('user_id', student.id).submissions?.find (submission) =>
        submission.user_id == @get('selectedStudent').id and
          submission.assignment_id == @get('selectedAssignment').id
      sub or {
        user_id: @get('selectedStudent').id
        assignment_id: @get('selectedAssignment').id
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

