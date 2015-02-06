define [
  'i18n!assignments'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/class/cache'
  'compiled/models/AssignmentGroup'
  'jst/assignments/ToggleShowBy'
], (I18n, $, _, Backbone, Cache, AssignmentGroup, template) ->

  class ToggleShowByView extends Backbone.View
    @optionProperty 'course'
    @optionProperty 'assignmentGroups'

    template: template

    els:
      '#show_by': '$showBy'
      '#show_by_date': '$showByDate'

    events:
      'click input': 'toggleShowBy'

    initialize: ->
      super
      @initialized = false
      @initializeCache()
      @course.on 'change', @initializeCache
      @course.on 'change', @render
      @assignmentGroups.once 'change:submissions', @initializeDateGroups
      @.on 'changed:showBy', @setAssignmentGroups
      @.on 'changed:showBy', @render

    initializeCache: =>
      return unless @course.get('id')?
      $.extend true, @, Cache
      @cache.use('localStorage') if ENV.current_user_id? # default: {}
      @cache.set(@cacheKey(), true) if !@cache.get(@cacheKey())?
      @initialized = true

    initializeDateGroups: =>
      assignments = _.flatten(@assignmentGroups.map (ag) -> ag.get('assignments').models)
      dated = _.select assignments, (a) -> a.dueAt()?
      undated = _.difference assignments, dated
      past = []
      overdue = []
      upcoming = []
      _.each(dated, (a) ->
        return upcoming.push a if new Date() < Date.parse(a.dueAt())

        isOverdue = a.allowedToSubmit() && a.withoutGradedSubmission()
        # only handles observer observing one student, this needs to change to handle multiple users in the future
        canHaveOverdueAssignment = !ENV.current_user_has_been_observer_in_this_course || ENV.observed_student_ids?.length == 1

        return overdue.push a if isOverdue && canHaveOverdueAssignment
        past.push a
      )

      overdue_group = new AssignmentGroup({ id: 'overdue', name: I18n.t('overdue_assignments', 'Overdue Assignments'), assignments: overdue })
      upcoming_group = new AssignmentGroup({ id: 'upcoming', name: I18n.t('upcoming_assignments', 'Upcoming Assignments'), assignments: upcoming })
      undated_group = new AssignmentGroup({ id: 'undated', name: I18n.t('undated_assignments', 'Undated Assignments'), assignments: undated })
      past_group = new AssignmentGroup({ id: 'past', name: I18n.t('past_assignments', 'Past Assignments'), assignments: past })

      sorted_groups = @_sortGroups(overdue_group, upcoming_group, undated_group, past_group)

      @groupedByAG = @assignmentGroups.models
      @groupedByDate = sorted_groups

      @setAssignmentGroups()

    _sortGroups: (overdue, upcoming, undated, past) ->
      @_sortAscending overdue.get('assignments')
      @_sortAscending upcoming.get('assignments')
      @_sortDescending past.get('assignments')
      [overdue, upcoming, undated, past]

    _sortAscending: (assignments) ->
      assignments.comparator = (a) -> Date.parse(a.dueAt())
      assignments.sort()

    _sortDescending: (assignments) ->
      assignments.comparator = (a) -> new Date() - Date.parse(a.dueAt())
      assignments.sort()

    toJSON: ->
      visible: @initialized
      showByDate: @showByDate()

    afterRender: ->
      @$showBy?.buttonset()

    setAssignmentGroups: =>
      groups = if @showByDate() then @groupedByDate else @groupedByAG
      @setAssignmentGroupAssociations(groups)
      groups = _.select groups, (group) =>
        hasWeight = @course.get('apply_assignment_group_weights') and
          group.get('group_weight')? and
          group.get('group_weight') > 0
        group.get('assignments').length > 0 or hasWeight
      @assignmentGroups.reset(groups)

    setAssignmentGroupAssociations: (groups) ->
      for assignment_group in groups
        if assignment_group.get("assignments").models.length
          for assignment in assignment_group.get("assignments").models
            # we are keeping this change on the frontend only (for keyboard nav), will not persist in the db
            assignment.collection = assignment_group
            assignment.set('assignment_group_id', assignment_group.id)

    showByDate: ->
      return true unless @initialized
      @cache.get(@cacheKey())

    cacheKey: ->
      ["course", @course.get('id'), "user", ENV.current_user_id, "assignments_show_by_date"]

    toggleShowBy: (ev) =>
      ev.preventDefault()
      key = @cacheKey()
      showByDate = @$showByDate.is(':checked')
      currentlyByDate = @cache.get(key)
      if currentlyByDate != showByDate
        @cache.set(key, showByDate)
        @trigger 'changed:showBy'

      @assignmentGroups.trigger 'cancelSearch'
