define [
  'i18n!assignments'
  'underscore'
  'Backbone'
  'compiled/class/cache'
  'compiled/models/AssignmentGroup'
  'jst/assignments/ToggleShowBy'
], (I18n, _, Backbone, Cache, AssignmentGroup, template) ->

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
        if new Date() > Date.parse(a.dueAt())
          if a.expectsSubmission() && a.allowedToSubmit() && a.withoutGradedSubmission()
            overdue.push a
          else
            past.push a
        else
          upcoming.push a
      )

      past = _.sortBy(past, (a) -> (new Date()) - Date.parse(a.dueAt()))
      upcoming = _.sortBy(upcoming, (a) -> Date.parse(a.dueAt()))
      overdue = _.sortBy(overdue, (a) -> Date.parse(a.dueAt()))

      @groupedByAG = @assignmentGroups.models
      @groupedByDate = [
        new AssignmentGroup({ id: 'overdue', name: 'Overdue Assignments', assignments: overdue }),
        new AssignmentGroup({ id: 'upcoming', name: 'Upcoming Assignments', assignments: upcoming }),
        new AssignmentGroup({ id: 'undated', name: 'Undated Assignments', assignments: undated }),
        new AssignmentGroup({ id: 'past', name: 'Past Assignments', assignments: past })
      ]

      @setAssignmentGroups()

    toJSON: ->
      visible: @initialized
      showByDate: @showByDate()

    afterRender: ->
      @$showBy?.buttonset()

    setAssignmentGroups: =>
      groups = if @showByDate() then @groupedByDate else @groupedByAG
      groups = _.select groups, (group) =>
        hasWeight = @course.get('apply_assignment_group_weights') and
          group.get('group_weight')? and
          group.get('group_weight') > 0
        group.get('assignments').length > 0 or hasWeight
      @assignmentGroups.reset(groups)

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
