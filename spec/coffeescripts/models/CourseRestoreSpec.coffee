define [
  'Backbone'
  'compiled/models/CourseRestore'
  'jquery'
], (Backbone, CourseRestoreModel, $) ->
  progressCompletedJSON =
    completion: 0
    context_id: 4
    context_type: "Account"
    created_at: "2013-03-08T16:37:46-07:00"
    id: 28
    message: null
    tag: "course_batch_update"
    updated_at: "2013-03-08T16:37:46-07:00"
    url: "http://localhost:3000/api/v1/progress/28"
    user_id: 51
    workflow_state: "completed"

  progressQueuedJSON =
    completion: 0
    context_id: 4
    context_type: "Account"
    created_at: "2013-03-08T16:37:46-07:00"
    id: 28
    message: null
    tag: "course_batch_update"
    updated_at: "2013-03-08T16:37:46-07:00"
    url: "http://localhost:3000/api/v1/progress/28"
    user_id: 51
    workflow_state: "queued"

  courseJSON =
    account_id: 6
    course_code: "Super"
    default_view: "feed"
    end_at: null
    enrollments: []
    hide_final_grades: false
    id: 58
    name: "Super Fun Deleted Course"
    sis_course_id: null
    start_at: null
    workflow_state: "deleted"

  QUnit.module 'CourseRestore',
    setup: ->
      @account_id = 4
      @course_id = 42
      @courseRestore = new CourseRestoreModel account_id: @account_id
      @server = sinon.fakeServer.create()
      @clock = sinon.useFakeTimers()

    teardown: ->
      @server.restore()
      @clock.restore()
      @acocunt_id = null

  # Describes searching for a course by ID 
  test "triggers 'searching' when search is called", ->
    callback = @spy()

    @courseRestore.on 'searching', callback
    @courseRestore.search(@account_id)

    ok callback.called, "Searching event is called when searching"

  test "populates CourseRestore model with response, keeping its original account_id", ->
    @courseRestore.search(@course_id)

    @server.respond 'GET', @courseRestore.searchUrl(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(courseJSON)]

    equal @courseRestore.get('account_id'), @account_id, "account id stayed the same"
    equal @courseRestore.get('id'), courseJSON.id, "course id was updated"

  # Describes storing a course from its previous deleted state
  test "responds with a deffered object", ->
    dfd = @courseRestore.restore()
    ok $.isFunction dfd.done, "This is a deffered object"

  # a restored course should be populated with a deleted course with an after a search 
  # was made.
  test "restores a course after search finds a deleted course", 2, ->
    @courseRestore.search(@course_id)
    @server.respond 'GET', @courseRestore.searchUrl(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(courseJSON)]

    dfd = @courseRestore.restore()
    @server.respond 'PUT', "#{@courseRestore.baseUrl()}/?course_ids[]=#{@courseRestore.get('id')}&event=undelete", [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(progressQueuedJSON)]
    @clock.tick 1000

    @server.respond 'GET', progressQueuedJSON.url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(progressCompletedJSON)]

    ok dfd.isResolved(), "All ajax request in this deferred object should be resolved"
    equal @courseRestore.get('workflow_state'), 'unpublished'
