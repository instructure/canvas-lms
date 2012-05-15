define [
  'Backbone'
  'compiled/home/collections/CourseCollection'
], ({View}, CourseCollection) ->

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
      $el = $ event.target
      value = $el.data 'value'
      @trigger 'filter', value

    addCourse: (course) =>
      id = course.get 'id'
      course_code = course.get 'course_code'
      @$('.courseList').append "<li><a href='#' data-value='course:#{id}'>#{course_code}</a></li>"

    render: ->
      @$el.html """
        <header class="toolbar">&nbsp;</header>
        <div class="list-view">
          <ul class="filterList">
            <li><a href="#" class="selected" data-value="everything">Everything</a>
          </ul>

          <header>Courses</header>
          <ul class="courseList">
            <li><a>Loading...</a></li>
          </ul>

          <header>Canvas Network</header>
          <ul class="community">
            <li><a href="#" data-value="peopleIFollow">People I Follow</a>
            <li><a href="#" data-value="popular">Popular</a>
            <li><a href="#" data-value="questions">Questions</a>
          </ul>
          <ul class="communityUserCommunities filterList">
            <li><a href="#">TODO: fake data</a>
          </ul>
        </div>
      """
      super

