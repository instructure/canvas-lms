define [
  'i18n!assignments'
  'underscore'
  'Backbone'
  'compiled/class/cache'
  'compiled/collections/AssignmentCollection'
  'jst/assignments/ToggleShowBy'
], (I18n, _, Backbone, Cache, AssignmentCollection, template) ->

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
      @firstResetLanded = @assignmentGroups.length > 0

      @course.on 'change', @initializeCache
      @course.on 'change', @render
      @assignmentGroups.on 'reset', @initializeDateGroups
      @.on 'changed:showBy', @setAssignmentGroups
      @.on 'changed:showBy', @render

    initializeCache: =>
      $.extend true, @, Cache
      @cache.use('localStorage') if ENV.current_user_id? # default: {}
      @cache.set(@cacheKey(), true) if !@cache.get(@cacheKey())?
      @initialized = true

    initializeDateGroups: =>
      unless @firstResetLanded
        @firstResetLanded = true

        assignments = _.flatten(@assignmentGroups.map (ag) -> ag.get('assignments').models)
        dated = _.select assignments, (a) -> a.dueAt()?
        undated = _.difference assignments, dated
        past = _.chain(dated)
          .select((a) -> (new Date()) > Date.parse(a.dueAt()))
          .sortBy((a) -> (new Date()) - Date.parse(a.dueAt()))
          .value()
        upcoming = _.chain(dated)
          .difference(past)
          .sortBy((a) -> Date.parse(a.dueAt()))
          .value()
        overdue = []

        @groupedByAG = @assignmentGroups.models
        @groupedByDate = [
          new Backbone.Model({ id: 'overdue', name: 'Overdue Assignments', assignments: new AssignmentCollection(overdue) }),
          new Backbone.Model({ id: 'upcoming', name: 'Upcoming Assignments', assignments: new AssignmentCollection(upcoming) }),
          new Backbone.Model({ id: 'undated', name: 'Undated Assignments', assignments: new AssignmentCollection(undated) }),
          new Backbone.Model({ id: 'past', name: 'Past Assignments', assignments: new AssignmentCollection(past) })
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
