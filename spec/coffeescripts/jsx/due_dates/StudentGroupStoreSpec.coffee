define [
  'underscore'
  'jsx/due_dates/StudentGroupStore',
  'helpers/fakeENV'
], (_, StudentGroupStore, fakeENV) ->


  module 'StudentGroupStore',
    setup: ->
      StudentGroupStore.reset()
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @server = sinon.fakeServer.create()
      @responseA = [
        {id: 1, title: "group A", group_category_id: 1}
        {id: 2, title: "group B", group_category_id: 1}
      ]
      @responseB = [
        {id: 3, title: "group C", group_category_id: 1}
        {id: 4, title: "group D", group_category_id: 1}
      ]

      # single page
      @server.respondWith "GET", "/api/v1/courses/1/groups", [200, {"Content-Type":"application/json", "Link": {}}, JSON.stringify(@responseA)]

      linkHeaders1 = '<http://api/v1/courses/2/groups?page=2&per_page=2>; rel="next",' +
        '<http://api/v1/courses/2/groups?page=1&per_page=2>; rel="current",'
        '<http://api/v1/courses/2/groups?page=1&per_page=2>; rel="first",' +
        '<http://api/v1/courses/2/groups?page=2&per_page=2>; rel="last"'

      # multiple pages
      @server.respondWith "GET", "/api/v1/courses/2/groups", [200, {"Content-Type":"application/json", "Link": linkHeaders1 }, JSON.stringify(@responseA)]
      @server.respondWith "GET", "http://api/v1/courses/2/groups?page=2&per_page=2", [200, {"Content-Type":"application/json"}, JSON.stringify(@responseB)]

    teardown: ->
      @server.restore()
      StudentGroupStore.reset()
      fakeENV.teardown()

  # ==================
  #   GETTING STATE
  # ==================

  test 'returns groups', ->
    someArbitraryVal = "foo"
    StudentGroupStore.setState({groups: someArbitraryVal})
    equal StudentGroupStore.getGroups(), someArbitraryVal

  test 'returns selected group set id', ->
    someArbitraryID = 22
    StudentGroupStore.setState({selectedGroupSetId: someArbitraryID})
    equal StudentGroupStore.getSelectedGroupSetId(), someArbitraryID

  test 'returns groupls filtered by selected group set', ->
    g3 = {id: 3, title: "group C", group_category_id: 3}
    groups = {
      1: {id: 1, title: "group A", group_category_id: 1},
      2: {id: 2, title: "group B", group_category_id: 1},
      3: g3
    }

    StudentGroupStore.setState({
      groups: groups,
      selectedGroupSetId: 3
    })

    deepEqual(
      StudentGroupStore.groupsFilteredForSelectedSet(),
      [g3]
    )

  # ==================
  #   SETTING STATE
  # ==================

  test 'adding groups works', ->
    g1 = {id: 1, title: "group 1"}
    initialGroups = {1: g1}
    g2 = {id: 2, title: "group 2"}
    arrayOfGroups = [{id: 2, title: "group 2"}]
    StudentGroupStore.setState({
      groups: initialGroups
    })

    StudentGroupStore.addGroups(arrayOfGroups)

    deepEqual(
      StudentGroupStore.getGroups(),
      _.indexBy([g1, g2], "id")
    )

  # ==================
  #  FETCHING GROUPS
  # ==================

  test 'groups are added to state once fetched', ->
    StudentGroupStore.fetchGroupsForCourse("/api/v1/courses/1/groups")
    @server.respond()

    equal(
      StudentGroupStore.getGroups()[1]["title"],
      "group A"
    )

  test 'multiple calls are made if server has multiple pages', ->
    ENV.context_asset_string = "course_2"
    StudentGroupStore.fetchGroupsForCourse()
    @server.respond()
    equal _.values(StudentGroupStore.getGroups()).length, 2
    equal StudentGroupStore.fetchComplete(), false
    @server.respond()
    equal _.values(StudentGroupStore.getGroups()).length, 4
    equal StudentGroupStore.fetchComplete(), true
