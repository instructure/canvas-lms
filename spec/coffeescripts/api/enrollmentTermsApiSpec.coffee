define [
  'jquery'
  'helpers/fakeENV',
  'compiled/api/enrollmentTermsApi'
  'jquery.ajaxJSON'
], ($, fakeENV, api) ->
  deserializedTerms = [
    {
      id: "1",
      name: "Fall 2013 - Art",
      startAt: new Date("2013-06-03T02:57:42Z"),
      endAt: new Date("2013-12-03T02:57:53Z"),
      createdAt: new Date("2015-10-27T16:51:41Z"),
      gradingPeriodGroupId: "2"
    },{
      id: "3",
      name: null,
      startAt: new Date("2014-01-03T02:58:36Z"),
      endAt: new Date("2014-03-03T02:58:42Z"),
      createdAt: new Date("2013-06-02T17:29:19Z"),
      gradingPeriodGroupId: "2"
    },{
      id: "4",
      name: null,
      startAt: null,
      endAt: null,
      createdAt: new Date("2014-05-02T17:29:19Z"),
      gradingPeriodGroupId: "1"
    }
  ]

  serializedTerms = {
    enrollment_terms: [
      {
        id: 1,
        name: "Fall 2013 - Art",
        start_at: "2013-06-03T02:57:42Z",
        end_at: "2013-12-03T02:57:53Z",
        created_at: "2015-10-27T16:51:41Z",
        grading_period_group_id: 2
      },{
        id: 3,
        name: null,
        start_at: "2014-01-03T02:58:36Z",
        end_at: "2014-03-03T02:58:42Z",
        created_at: "2013-06-02T17:29:19Z",
        grading_period_group_id: 2
      },{
        id: 4,
        name: null,
        start_at: null,
        end_at: null,
        created_at: "2014-05-02T17:29:19Z",
        grading_period_group_id: 1
      }
    ]
  }

  module "list",
    setup: ->
      @server = sinon.fakeServer.create()
      @fakeHeaders = '<http://some_url?page=1&per_page=10>; rel="last"'
      fakeENV.setup()
      ENV.ENROLLMENT_TERMS_URL = 'api/enrollment_terms'
    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test "calls the resolved endpoint", ->
    @stub($, 'ajaxJSON')
    api.list()
    ok $.ajaxJSON.calledWith('api/enrollment_terms')

  asyncTest "deserializes returned enrollment terms", ->
    @server.respondWith "GET", /enrollment_terms/, [200, {"Content-Type":"application/json", "Link": @fakeHeaders}, JSON.stringify serializedTerms]
    api.list()
       .then (terms) =>
          deepEqual terms, deserializedTerms
          start()
    @server.respond()

  # TODO fixup CheatDepaginator for failure conditions
  # asyncTest "SKIPPED: rejects the promise upon errors", ->
  #    @server.respondWith "GET", /enrollment_terms/, [404, {"Content-Type":"application/json"}, "FAIL"]
  #    api.list().catch (error) =>
  #      equal error, "FAIL"
  #      start()
  #    @server.respond()
