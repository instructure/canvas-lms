define [
  'Backbone'
  'compiled/models/AssignmentGroup'
  'underscore'
  'i18n!assignments'
  'compiled/collections/PaginatedCollection'
], (Backbone, AssignmentGroup, _, I18n, PaginatedCollection) ->

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
      $.get(ENV.URLS.context_modules_url).then (modules) =>
        moduleNames = {}
        for m in modules
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

    getGrades: ->
      collection = new PaginatedCollection
      collection.url = => "#{@courseSubmissionsURL}?per_page=#{PER_PAGE_LIMIT}"
      collection.loadAll = true
      collection.on 'fetched:last', =>
        @loadGradesFromSubmissions(collection.toArray())
      collection.fetch()

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