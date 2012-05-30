define [
  'Backbone'
  'compiled/collections/CourseCollection'
  'jst/activityFeed/ActivityFeedFilterView'
], ({View}, CourseCollection, template) ->

  class ActivityFeedFilterView extends View

    events:
      'click a': 'clickFilter'

    initialize: ->
      @courseCollection = new CourseCollection
      @courseCollection.on 'add', @addCourse
      @courseCollection.on 'reset', => @courseCollection.each @addCourse
      @courseCollection.fetch
        # remove the "loading..." indicator element
        success: => @$('.courseList li:first').remove()

    clickFilter: (event) ->
      event.preventDefault()
      $el = $ event.currentTarget
      value = $el.data 'value'
      @$active.removeClass 'active'
      @$active = $el.addClass 'active'
      @trigger 'filter', value

    addCourse: (course) =>
      id = course.get 'id'
      course_code = course.get 'course_code'
      @$('.courseList').append "<li><a href='#' data-value='course:#{id}'>#{course_code}</a></li>"

    render: ->
      @$el.html template()
      @$active = @$ '.active'
      super
