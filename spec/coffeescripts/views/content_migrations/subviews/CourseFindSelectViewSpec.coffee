define [
  'Backbone'
  'compiled/views/content_migrations/subviews/CourseFindSelectView'
], (Backbone, CourseFindSelectView) ->
  module 'CourseFindSelectView: #setSourceCourseId'
  test 'Triggers "course_changed" when course is found by its id', ->
    courseFindSelectView = new CourseFindSelectView
                           model: new Backbone.Model


    course = {id: 42}
    courseFindSelectView.courses = [course]
    courseFindSelectView.render()

    sinonSpy = @spy(courseFindSelectView, 'trigger')
    courseFindSelectView.setSourceCourseId 42

    ok sinonSpy.calledWith('course_changed', course), "Triggered course_changed with a course"
