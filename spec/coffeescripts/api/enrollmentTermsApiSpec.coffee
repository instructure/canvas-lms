define [
  'axios',
  'helpers/fakeENV',
  'compiled/api/enrollmentTermsApi'
], (axios, fakeENV, api) ->
  deserializedTerms = [
    {
      id: 1,
      name: "Fall 2013 - Art",
      startAt: new Date("2013-06-03T02:57:42Z"),
      endAt: new Date("2013-12-03T02:57:53Z"),
      createdAt: new Date("2015-10-27T16:51:41Z"),
      gradingPeriodGroupId: 2
    },{
      id: 3,
      name: null,
      startAt: new Date("2014-01-03T02:58:36Z"),
      endAt: new Date("2014-03-03T02:58:42Z"),
      createdAt: new Date("2013-06-02T17:29:19Z"),
      gradingPeriodGroupId: 2
    },{
      id: 4,
      name: null,
      startAt: null,
      endAt: null,
      createdAt: new Date("2014-05-02T17:29:19Z"),
      gradingPeriodGroupId: 1
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
      fakeENV.setup()
      ENV.ENROLLMENT_TERMS_URL = 'api/enrollment_terms'
    teardown: ->
      fakeENV.teardown()

  test "calls the resolved endpoint", ->
    apiSpy = @stub(axios, "get").returns(new Promise(->))
    api.list()
    ok axios.get.calledWith('api/enrollment_terms')

  asyncTest "deserializes returned enrollment terms", ->
    successPromise = new Promise (resolve) => resolve({ data: serializedTerms })
    @stub(axios, "get").returns(successPromise)
    api.list()
       .then (terms) =>
          deepEqual terms, deserializedTerms
          start()

  asyncTest "rejects the promise upon errors", ->
    successPromise = new Promise (_, reject) => reject("FAIL")
    @stub(axios, "get").returns(successPromise)
    api.list().catch (error) =>
      equal error, "FAIL"
      start()
