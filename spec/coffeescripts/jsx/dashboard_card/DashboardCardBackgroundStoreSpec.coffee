define [
  'react-addons-test-utils'
  'underscore'
  'jsx/dashboard_card/DashboardCardBackgroundStore'
  'helpers/fakeENV'
], ({Simulate, SimulateNative}, _, DashboardCardBackgroundStore, fakeENV) ->

  TEST_COLORS = {
    '#008400',
    '#91349B',
    '#E1185C'
  }

  DashboardCardBackgroundStore.reset = () ->
    @setState
      courseColors: TEST_COLORS
      usedDefaults: []

  module 'DashboardCardBackgroundStore',
    setup: ->
      DashboardCardBackgroundStore.reset()
      fakeENV.setup()
      ENV.PREFERENCES = {custom_colors: TEST_COLORS}
      ENV.current_user_id = 22

      @server = sinon.fakeServer.create()
      @response = []

      @server.respondWith "POST", "/api/v1/users/22/colors/course_1", [200, {"Content-Type":"application/json"}, ""]
      @server.respondWith "POST", "/api/v1/users/22/colors/course_2", [200, {"Content-Type":"application/json"}, ""]
      @server.respondWith "POST", "/api/v1/users/22/colors/course_3", [200, {"Content-Type":"application/json"}, ""]

    teardown: ->
      @server.restore()
      DashboardCardBackgroundStore.reset()
      fakeENV.teardown()

  # ================================
  #  GETTING CUSTOM COLORS FROM ENV
  # ================================

  test 'gets colors from env', ->
    deepEqual DashboardCardBackgroundStore.getCourseColors(), TEST_COLORS

  # ===================
  #   DEFAULT COLORS
  # ===================

  test 'will not reuse a color if it is used more than the others', ->
    ok _.include(DashboardCardBackgroundStore.leastUsedDefaults(), '#008400')
    DashboardCardBackgroundStore.setState({usedDefaults: ['#008400']})
    ok !_.include(DashboardCardBackgroundStore.leastUsedDefaults(), '#008400')

  test 'maintains list of used defaults', ->
    ok !_.include(DashboardCardBackgroundStore.getUsedDefaults(), '#91349B')
    DashboardCardBackgroundStore.markColorUsed('#91349B')
    ok _.include(DashboardCardBackgroundStore.getUsedDefaults(), '#91349B')

  test 'posts to the server when a default is set', ->
    DashboardCardBackgroundStore.setDefaultColor("course_1")
    ok @server.requests[0].url.match(/course_1/)
    equal @server.requests.length, 1
    @server.respond()

  test 'sets multiple defaults properly', ->
    DashboardCardBackgroundStore.setDefaultColors(["course_2", "course_3"])
    ok @server.requests[0].url.match(/course_2/)
    ok @server.requests[1].url.match(/course_3/)
    equal @server.requests.length, 2
    @server.respond()

  # ==========================
  #    UPDATING CUSTOM COLOR
  # ==========================

  test 'sets a custom color properly', ->
    DashboardCardBackgroundStore.setState({courseColors: {foo: "bar"}})
    equal DashboardCardBackgroundStore.colorForCourse("foo"), "bar"

    DashboardCardBackgroundStore.setColorForCourse("foo", "baz")
    equal DashboardCardBackgroundStore.colorForCourse("foo"), "baz"

