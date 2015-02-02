define [
  'jquery'
  'Backbone'
  'compiled/models/AssignmentGroup'
  'underscore'
  'i18n!assignments'
  'compiled/collections/SubmissionCollection'
  'compiled/collections/ModuleCollection'
], ($, Backbone, AssignmentGroup, _, I18n, SubmissionCollection, ModuleCollection) ->

  PER_PAGE_LIMIT = 50

  class AssignmentGroupCollection extends Backbone.Collection

    model: AssignmentGroup

    @optionProperty 'course'
    @optionProperty 'courseSubmissionsURL'

    # TODO: this will also return the assignments discussion_topic if it is of
    # that type, which we don't need.
    defaults:
      params:
        include: ["assignments"]

    loadModuleNames: ->
      modules = new ModuleCollection([], {course_id: @course.id})
      modules.loadAll = true
      modules.fetch()
      modules.on 'fetched:last', =>
        moduleNames = {}
        for m in modules.toJSON()
          moduleNames[m.id] = m.name

        for assignment in @assignments()
          assignmentModuleNames = _(assignment.get 'module_ids')
            .map (id) -> moduleNames[id]
          assignment.set('modules', assignmentModuleNames)

    assignments: ->
      @chain()
        .map((ag) -> ag.get('assignments').toArray())
        .flatten()
        .value()

    comparator: 'position'

    userIsStudent: ->
      _.include(ENV.current_user_roles, "student")

    getGrades: ->
      if @userIsStudent() || ENV.observed_student_ids.length == 1
        collection = new SubmissionCollection
        if @userIsStudent()
          collection.url = => "#{@courseSubmissionsURL}?per_page=#{PER_PAGE_LIMIT}"
        else
          collection.url = => "#{@courseSubmissionsURL}?student_ids[]=#{ENV.observed_student_ids[0]}&per_page=#{PER_PAGE_LIMIT}"
        collection.loadAll = true
        collection.on 'fetched:last', =>
          @loadGradesFromSubmissions(collection.toArray())
        collection.fetch()
      else
        @trigger 'change:submissions'

    loadGradesFromSubmissions: (submissions) ->
      submissionsHash = {}
      for submission in submissions
        submissionsHash[submission.get('assignment_id')] = submission

      for assignment in @assignments()
        submission = submissionsHash[assignment.get('id')]
        if submission
          if submission.get('grade')?
            grade = parseFloat submission.get('grade')
            # may be a letter grade like 'A-'
            if !isNaN grade
              submission.set 'grade', grade
          else
            submission.set 'notYetGraded', true
          assignment.set 'submission', submission
        else
          # manually trigger a change so the UI can update appropriately.
          assignment.set 'submission', null
          assignment.trigger 'change:submission'

      @trigger 'change:submissions'
