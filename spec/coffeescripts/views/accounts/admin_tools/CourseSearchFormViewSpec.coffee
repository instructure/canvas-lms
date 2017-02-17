define [
  'Backbone'
  'compiled/models/CourseRestore'
  'compiled/views/accounts/admin_tools/CourseSearchFormView'
  'jquery'
], (Backbone, CourseRestore, CourseSearchFormView, $) ->
  QUnit.module 'CourseSearchFormView',
    setup: ->
      @course_id = 42
      @courseRestore = new CourseRestore account_id: 4
      @courseSearchFormView = new CourseSearchFormView model: @courseRestore

      $("#fixtures").append @courseSearchFormView.render().el

    teardown: ->
      @courseSearchFormView.remove()


  test "#search, when form is submited, search is called", ->
    @mock(@courseRestore).expects("search").once().
      returns($.Deferred().resolve())

    @courseSearchFormView.$courseSearchField.val(@course_id)
    @courseSearchFormView.$el.submit()

  test "#search shows an error when given a blank query", ->
    @mock(@courseSearchFormView.$courseSearchField).expects("errorBox").once()

    @courseSearchFormView.$el.submit()
