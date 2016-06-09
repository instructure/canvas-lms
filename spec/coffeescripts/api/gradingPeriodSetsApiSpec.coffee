define [
  'axios',
  'helpers/fakeENV',
  'compiled/api/gradingPeriodSetsApi'
], (axios, fakeENV, api) ->
  deserializedSets = [
    {
      id: "1",
      title: "Fall 2015",
      gradingPeriods: [
        {
          id: "1",
          title: "Q1",
          startDate: new Date("2015-09-01T12:00:00Z"),
          endDate: new Date("2015-10-31T12:00:00Z")
        },{
          id: "2",
          title: "Q2",
          startDate: new Date("2015-11-01T12:00:00Z"),
          endDate: new Date("2015-12-31T12:00:00Z")
        }
      ],
      permissions: { read: true, create: true, update: true, delete: true }
    },{
      id: "2",
      title: "Spring 2016",
      gradingPeriods: [],
      permissions: { read: true, create: true, update: true, delete: true }
    }
  ]

  serializedSets = {
    grading_period_sets: [
      {
        id: "1",
        title: "Fall 2015",
        grading_periods: [
          {
            id: "1",
            title: "Q1",
            start_date: new Date("2015-09-01T12:00:00Z"),
            end_date: new Date("2015-10-31T12:00:00Z")
          },{
            id: "2",
            title: "Q2",
            start_date: new Date("2015-11-01T12:00:00Z"),
            end_date: new Date("2015-12-31T12:00:00Z")
          }
        ],
        permissions: { read: true, create: true, update: true, delete: true }
      },
      {
        id: "2",
        title: "Spring 2016",
        grading_periods: [],
        permissions: { read: true, create: true, update: true, delete: true }
      }
    ]
  }

  module "list",
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
    teardown: ->
      fakeENV.teardown()

  test "calls the resolved endpoint", ->
    apiSpy = @stub(axios, "get").returns(new Promise(->))
    api.list()
    ok axios.get.calledWith('api/grading_period_sets')

  asyncTest "deserializes returned grading period sets", ->
    successPromise = new Promise (resolve) => resolve({ data: serializedSets })
    @stub(axios, "get").returns(successPromise)
    api.list()
       .then (sets) =>
          deepEqual sets, deserializedSets
          start()

  asyncTest "rejects the promise upon errors", ->
    failurePromise = new Promise (_, reject) => reject("FAIL")
    @stub(axios, "get").returns(failurePromise)
    api.list().catch (error) =>
      equal error, "FAIL"
      start()

  deserializedSetCreating = {
    title: "Fall 2015",
    enrollmentTermIDs: [ "1", "2" ]
  }

  deserializedSetCreated = {
    id: "1",
    title: "Fall 2015",
    gradingPeriods: [],
    enrollmentTermIDs: [ "1", "2" ],
    permissions: { read: true, create: true, update: true, delete: true }
  }

  serializedSetCreating = {
    grading_period_set: { title: "Fall 2015" },
    enrollment_term_ids: [ "1", "2" ]
  }

  serializedSetCreated = {
    grading_period_set: {
      id: "1",
      title: "Fall 2015",
      enrollment_term_ids: [ "1", "2" ],
      grading_periods: [],
      permissions: { read: true, create: true, update: true, delete: true }
    }
  }

  module "create",
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
    teardown: ->
      fakeENV.teardown()

  test "calls the resolved endpoint with the serialized grading period set", ->
    apiSpy = @stub(axios, "post").returns(new Promise(->))
    api.create(deserializedSetCreating)
    ok axios.post.calledWith('api/grading_period_sets', serializedSetCreating)

  asyncTest "deserializes returned grading period sets", ->
    successPromise = new Promise (resolve) => resolve({ data: serializedSetCreated })
    @stub(axios, "post").returns(successPromise)
    api.create(deserializedSetCreating)
       .then (set) =>
          deepEqual set, deserializedSetCreated
          start()

  asyncTest "rejects the promise upon errors", ->
    failurePromise = new Promise (_, reject) => reject("FAIL")
    @stub(axios, "post").returns(failurePromise)
    api.create(deserializedSetCreating).catch (error) =>
      equal error, "FAIL"
      start()

  deserializedSetUpdating = {
    id: "1",
    title: "Fall 2015",
    enrollmentTermIDs: [ "1", "2" ],
    permissions: { read: true, create: true, update: true, delete: true }
  }

  serializedSetUpdating = {
    grading_period_set: { title: "Fall 2015" },
    enrollment_term_ids: [ "1", "2" ]
  }

  serializedSetUpdated = {
    grading_period_set: {
      id: "1",
      title: "Fall 2015",
      enrollment_term_ids: [ "1", "2" ],
      grading_periods: [
        {
          id: "1",
          title: "Q1",
          start_date: new Date("2015-09-01T12:00:00Z"),
          end_date: new Date("2015-10-31T12:00:00Z")
        },{
          id: "2",
          title: "Q2",
          start_date: new Date("2015-11-01T12:00:00Z"),
          end_date: new Date("2015-12-31T12:00:00Z")
        }
      ],
      permissions: { read: true, create: true, update: true, delete: true }
    }
  }

  module "update",
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIOD_SET_UPDATE_URL = 'api/grading_period_sets/%7B%7B%20id%20%7D%7D'
    teardown: ->
      fakeENV.teardown()

  test "calls the resolved endpoint with the serialized grading period set", ->
    apiSpy = @stub(axios, "patch").returns(new Promise(->))
    api.update(deserializedSetUpdating)
    ok axios.patch.calledWith('api/grading_period_sets/1', serializedSetUpdating)

  asyncTest "returns the given grading period set", ->
    successPromise = new Promise (resolve) => resolve({ data: serializedSetUpdated })
    @stub(axios, "patch").returns(successPromise)
    api.update(deserializedSetUpdating)
       .then (set) =>
          deepEqual set, deserializedSetUpdating
          start()

  asyncTest "rejects the promise upon errors", ->
    failurePromise = new Promise (_, reject) => reject("FAIL")
    @stub(axios, "patch").returns(failurePromise)
    api.update(deserializedSetUpdating).catch (error) =>
      equal error, "FAIL"
      start()
