define [
  'Backbone'
  'compiled/views/content_migrations/CopyCourseView'
  'compiled/views/content_migrations/subviews/DateShiftView'
], (Backbone, CopyCourseView, DateShiftView) ->
  module 'CopyCourseView: Initializer'
  test 'after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', ->

    copyCourseView = new CopyCourseView
                         courseFindSelect: new Backbone.View
                         dateShift: new DateShiftView

    $('#fixtures').html copyCourseView.render().el
    sinonSpy = sinon.spy(copyCourseView.dateShift, 'updateNewDates')
    course = {start_at: 'foo', end_at: 'bar'}
    copyCourseView.courseFindSelect.trigger 'course_changed', course
    ok sinonSpy.calledWith(course), "Called updateNewDates with passed in object"

    copyCourseView.remove()

