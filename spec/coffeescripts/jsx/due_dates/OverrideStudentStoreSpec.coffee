define [
  'react'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/OverrideStudentStore',
  'helpers/fakeENV'
], (React, {Simulate, SimulateNative}, _, OverrideStudentStore, fakeENV) ->

  module 'OverrideStudentStore',
    setup: ->
      OverrideStudentStore.reset()
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @server = sinon.fakeServer.create()
      @response = [
        {"id":"2","name":"Publius Publicola","sortable_name":"Publicola, Publius","short_name":"Publius"}
        {"id":"5","name":"Publius Scipio","sortable_name":"Scipio, Publius","short_name":"Publius"}
      ]
      # by id
      @server.respondWith "GET", "/api/v1/courses/1/users?user_ids%5B%5D=2&user_ids%5B%5D=5&enrollment_type=student", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      # by name
      @server.respondWith "GET", "/api/v1/courses/1/search_users", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      @server.respondWith "GET", "/api/v1/courses/1/search_users?search_term=publiu&enrollment_type=student&include_inactive=false", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      @server.respondWith "GET", "/api/v1/courses/1/search_users?search_term=publiu", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      # by course
      url = (page) -> "/api/v1/courses/1/users?per_page=50&page=" + page + "&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids"
      @server.respondWith "GET", url(1), [200, {"Content-Type":"application/json"}, JSON.stringify([])]
      @server.respondWith "GET", url(2), [200, {"Content-Type":"application/json"}, JSON.stringify([])]
      @server.respondWith "GET", url(3), [200, {"Content-Type":"application/json"}, JSON.stringify([])]
      @server.respondWith "GET", url(4), [200, {"Content-Type":"application/json"}, JSON.stringify([])]

    teardown: ->
      @server.restore()
      OverrideStudentStore.reset()
      fakeENV.teardown()

  # =============================
  #  GETTING STUDENTS FROM STATE
  # =============================

  test 'returns students', ->
    someArbitraryVal = "foo"
    OverrideStudentStore.setState({students: someArbitraryVal})
    equal OverrideStudentStore.getStudents(), someArbitraryVal

  # ================
  #  FETCHING BY ID
  # ================

  test 'can properly fetch by ID', ->
    OverrideStudentStore.fetchStudentsByID([2,5])
    @server.respond()

    # matches one of the responses defined in setup
    equal 200, this.server.requests[0].status

    results = _.map(OverrideStudentStore.getStudents(), (student) -> student.id)
    deepEqual results, ['2','5']

  test 'does not fetch by ID if no IDs given', ->
    OverrideStudentStore.fetchStudentsByID([])
    equal this.server.requests.length, 0

  # ==================
  #  FETCHING BY NAME
  # ==================

  test 'can properly fetch a student by name', ->
    OverrideStudentStore.fetchStudentsByName("publiu")
    @server.respond()
    # matches one of the responses defined in setup
    equal 200, this.server.requests[0].status

  test 'sets currentlySearching properly', ->
    equal false, OverrideStudentStore.currentlySearching()
    OverrideStudentStore.fetchStudentsByName("publiu")
    equal true, OverrideStudentStore.currentlySearching()
    @server.respond()
    equal false, OverrideStudentStore.currentlySearching()

  test 'fetches students by same name only once', ->
    OverrideStudentStore.fetchStudentsByName("publiu")
    @server.respond()
    # wont make call again
    OverrideStudentStore.fetchStudentsByName("publiu")
    equal 1, @server.requests.length

  test 'does not fetch if allStudentsFetched is true', ->
    OverrideStudentStore.setState({allStudentsFetched: true})
    OverrideStudentStore.fetchStudentsByName("Mike Jones")
    equal this.server.requests.length, 0

  # ====================
  #  FETCHING BY COURSE
  # ====================

  test 'can properly fetch by course', ->
    OverrideStudentStore.fetchStudentsForCourse()
    equal 4, @server.requests.length
    @server.respond()
    # matches one of the responses defined in setup
    equal @server.requests[0].status, 200

  test 'if all users returned, will set allStudentsFetched to true', ->
    equal OverrideStudentStore.allStudentsFetched(), false
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    # server returned no links.next in headers
    equal OverrideStudentStore.allStudentsFetched(), true
