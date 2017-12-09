#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/OverrideStudentStore',
  'helpers/fakeENV'
], (React, {Simulate, SimulateNative}, _, OverrideStudentStore, fakeENV) ->

  QUnit.module 'OverrideStudentStore',
    setup: ->
      OverrideStudentStore.reset()
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @server = sinon.fakeServer.create()
      @response = [
        {
          id: "2",
          name: "Publius Publicola",
          sortable_name: "Publicola, Publius",
          short_name: "Publius",
          group_ids: ["1", "9"],
          enrollments: [{ id: "7", course_section_id: "2", type: "StudentEnrollment" }]
        }
        {
          id: "5",
          name: "Publius Scipio",
          sortable_name: "Scipio, Publius",
          short_name: "Publius",
          group_ids: ["3"],
          enrollments: [{ id: "8", course_section_id: "4", type: "StudentEnrollment" }]
        }
      ]
      @response2 = [
        {
          id: "7",
          name: "Publius Varus",
          sortable_name: "Varus, Publius",
          short_name: "Publius"
        }
      ]
      # by id
      @server.respondWith "GET", "/api/v1/courses/1/users?user_ids=2%2C5&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      # by id paginated
      @server.respondWith "GET", "/api/v1/courses/1/users?user_ids=2%2C5%2C7&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids", [200, {"Content-Type":"application/json", "Link":'<http://page2>; rel="next"'}, JSON.stringify(@response)]
      @server.respondWith "GET", "http://page2", [200, {"Content-Type":"application/json"}, JSON.stringify(@response2)]
      # by name
      @server.respondWith "GET", "/api/v1/courses/1/search_users", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      @server.respondWith "GET", "/api/v1/courses/1/search_users?search_term=publiu&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      @server.respondWith "GET", "/api/v1/courses/1/search_users?search_term=publiu", [200, {"Content-Type":"application/json"}, JSON.stringify(@response)]
      # by course
      @server.respondWith "GET", "/api/v1/courses/1/users?per_page=50&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids", [200, {"Content-Type":"application/json", "Link":'<http://coursepage2>; rel="next"'}, JSON.stringify(@response)]

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

  test 'fetching by id: includes sections on the students', ->
    OverrideStudentStore.fetchStudentsByID([2,5])
    @server.respond()
    sections = _.map(OverrideStudentStore.getStudents(), (student) -> student.sections)
    propEqual sections, [['2'], ['4']]

  test 'fetching by id: includes group_ids on the students', ->
    OverrideStudentStore.fetchStudentsByID([2,5])
    @server.respond()
    groups = _.map(OverrideStudentStore.getStudents(), (student) -> student.group_ids)
    propEqual groups, [['1', '9'], ['3']]

  test 'fetching by id: fetches multiple pages if necessary', ->
    OverrideStudentStore.fetchStudentsByID([2,5,7])

    # respond to first page
    @server.respond()

    # 2 requests made by here: initial, and followup that's still pending in the queue
    equal @server.requests.length, 2
    equal @server.queue.length, 1

    # respond to second page
    @server.respond()

    # should not have a third request pending
    equal @server.requests.length, 2
    equal @server.queue.length, 0

    # should have combined the results
    results = _.map(OverrideStudentStore.getStudents(), (student) -> student.id)
    deepEqual results, ['2','5','7']

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

  test 'fetching by name: includes sections on the students', ->
    OverrideStudentStore.fetchStudentsByName("publiu")
    @server.respond()
    sections = _.map(OverrideStudentStore.getStudents(), (student) -> student.sections)
    propEqual sections, [['2'], ['4']]

  test 'fetching by name: includes group_ids on the students', ->
    OverrideStudentStore.fetchStudentsByName("publiu")
    @server.respond()
    groups = _.map(OverrideStudentStore.getStudents(), (student) -> student.group_ids)
    propEqual groups, [['1', '9'], ['3']]

  # ====================
  #  FETCHING BY COURSE
  # ====================

  test 'can properly fetch by course', ->
    OverrideStudentStore.fetchStudentsForCourse()
    equal @server.requests.length, 1
    @server.respond()
    # matches one of the responses defined in setup
    equal @server.requests[0].status, 200

  test 'fetching by course: follows pagination up to the limit', ->
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    for i in [2..10]
      @server.respondWith "GET", "http://coursepage#{i}", [200, {"Content-Type":"application/json", "Link":"<http://coursepage#{i + 1}>; rel=\"next\""}, "[]"]
      @server.respond()
    equal @server.requests.length, 4
    equal OverrideStudentStore.allStudentsFetched(), false

  test 'fetching by course: saves results from all pages', ->
    @server.respondWith "GET", "http://coursepage2", [200, {"Content-Type":"application/json"}, JSON.stringify(@response2)]
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    @server.respond()
    # should have combined the results
    results = _.map(OverrideStudentStore.getStudents(), (student) -> student.id)
    deepEqual results, ['2','5','7']

  test 'fetching by course: if all users returned, sets allStudentsFetched to true', ->
    @server.respondWith "GET", "http://coursepage2", [200, {"Content-Type":"application/json"}, "[]"]
    equal OverrideStudentStore.allStudentsFetched(), false
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    @server.respond()
    # server returned no links.next in headers
    equal OverrideStudentStore.allStudentsFetched(), true

  test 'fetching by course: includes sections on the students', ->
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    sections = _.map(OverrideStudentStore.getStudents(), (student) -> student.sections)
    propEqual sections, [['2'], ['4']]

  test 'fetching by course: includes group_ids on the students', ->
    OverrideStudentStore.fetchStudentsForCourse()
    @server.respond()
    groups = _.map(OverrideStudentStore.getStudents(), (student) -> student.group_ids)
    propEqual groups, [['1', '9'], ['3']]
