define [
  'underscore',
  'jsx/epub_exports/CourseStore'
], (_, CourseStore) ->

  QUnit.module 'CourseEpubExportStoreSpec',
    setup: ->
      CourseStore.clearState()
      @courses = {
        courses: [{
          name: 'Maths 101',
          id: 1,
          epub_export: {
            id: 1
          }
        }, {
          name: 'Physics 101',
          id: 2
        }]
      }
      @server = sinon.fakeServer.create()

    teardown: ->
      CourseStore.clearState()
      @server.restore()

  test 'getAll', ->
    @server.respondWith('GET', '/api/v1/epub_exports', [
      200, {'Content-Type': 'application/json'},
      JSON.stringify(@courses)
    ])
    ok _.isEmpty(CourseStore.getState()), 'precondition'
    CourseStore.getAll()
    @server.respond()

    state = CourseStore.getState()
    _.each(@courses.courses, (course) ->
      deepEqual state[course.id], course
    )

  test 'get', ->
    url = "/api/v1/courses/1/epub_exports/1"
    course = @courses.courses[0]
    @server.respondWith('GET', url, [
      200, {'Content-Type': 'application/json'},
      JSON.stringify(course)
    ])
    ok _.isEmpty(CourseStore.getState()), 'precondition'
    CourseStore.get(1, 1)
    @server.respond()

    state = CourseStore.getState()
    deepEqual state[course.id], course

  test 'create', ->
    course_id = 3
    epub_export = {
      name: 'Creative Writing',
      id: course_id,
      epub_export: {
        permissions: {},
        workflow_state: 'created'
      }
    }
    @server.respondWith('POST', '/api/v1/courses/' + course_id + '/epub_exports', [
      200, {'Content-Type': 'application/josn'},
      JSON.stringify(epub_export)
    ])

    ok _.isUndefined(CourseStore.getState()[course_id]), 'precondition'
    CourseStore.create(course_id)
    @server.respond()

    state = CourseStore.getState()
    deepEqual state[course_id], epub_export, 'should add new object to state'
