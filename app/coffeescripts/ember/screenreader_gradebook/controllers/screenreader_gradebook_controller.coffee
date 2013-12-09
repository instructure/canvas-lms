define ['i18n!sr_gradebook', 'ember', 'underscore'], (I18n, Ember, _) ->

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  ScreenreaderGradebookController = Ember.ObjectController.extend

    sectionSelectDefaultLabel: I18n.t "all_sections", "All Sections"
    studentSelectDefaultLabel: I18n.t "no_student", "No Student Selected"
    assignmentSelectDefaultLabel: I18n.t "no_assignment", "No Assignment Selected"

    students: (->
      @get('enrollments').map (enrollment) -> enrollment.user
    ).property('enrollments.@each')

    assignments: (->
      _.flatten(@get('assignment_groups').map (ag) -> ag.assignments)
    ).property('assignment_groups.@each')

    selectedSection: (->
      @get('sections')[0]
    ).property('sections')

    selectedStudent: (->
      @get('students')[0]
    ).property('students')

    selectedAssignment: (->
      @get('assignments')[0]
    ).property('assignments')

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
