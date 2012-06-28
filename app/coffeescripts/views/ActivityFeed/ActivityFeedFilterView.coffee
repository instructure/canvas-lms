define [
  'Backbone'
  'compiled/collections/CourseCollection'
  'jst/activityFeed/ActivityFeedFilterView'
], ({View}, CourseCollection, template) ->

  class ActivityFeedFilterView extends View

    events:
      'click a': 'clickFilter'

    template: template

    els:
      '.active': '$active'

    initialize: ->
      @courses = @getCoursesFromENV()
      @communities = @getCommuntiesFromENV()
      @render()

    toJSON: ->
      {@courses, @communities}

    clickFilter: (event) ->
      event.preventDefault()
      $el = $ event.currentTarget
      value = $el.data 'value'
      @$active.removeClass 'active'
      @$active = $el.addClass 'active'
      @trigger 'filter', value

    getCoursesFromENV: ->
      course for k, course of ENV.CONTEXTS.courses when course.state in ['active', 'available']

    getCommuntiesFromENV: ->
      group for k, group of ENV.CONTEXTS.groups when group.category is 'Communities'

    addCourse: (course) ->
      ENV.CONTEXTS.courses[course.id] = course
      @courses = @getCoursesFromENV()
      @render()
      @$(".courseList a[data-value='course:#{course.id}']").click()
