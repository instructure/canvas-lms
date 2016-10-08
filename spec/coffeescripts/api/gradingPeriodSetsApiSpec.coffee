define [
  'axios'
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
          endDate: new Date("2015-10-31T12:00:00Z"),
          closeDate: new Date("2015-11-07T12:00:00Z")
        },{
          id: "2",
          title: "Q2",
          startDate: new Date("2015-11-01T12:00:00Z"),
          endDate: new Date("2015-12-31T12:00:00Z"),
          closeDate: new Date("2016-01-07T12:00:00Z")
        }
      ],
      permissions: { read: true, create: true, update: true, delete: true },
      createdAt: new Date("2015-12-29T12:00:00Z")
    },{
      id: "2",
      title: "Spring 2016",
      gradingPeriods: [],
      permissions: { read: true, create: true, update: true, delete: true },
      createdAt: new Date("2015-11-29T12:00:00Z")
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
            end_date: new Date("2015-10-31T12:00:00Z"),
            close_date: new Date("2015-11-07T12:00:00Z")
          },{
            id: "2",
            title: "Q2",
            start_date: new Date("2015-11-01T12:00:00Z"),
            end_date: new Date("2015-12-31T12:00:00Z"),
            close_date: new Date("2016-01-07T12:00:00Z")
          }
        ],
        permissions: { read: true, create: true, update: true, delete: true },
        created_at: "2015-12-29T12:00:00Z"
      },
      {
        id: "2",
        title: "Spring 2016",
        grading_periods: [],
        permissions: { read: true, create: true, update: true, delete: true },
        created_at: "2015-11-29T12:00:00Z"
      }
    ]
  }

  module "list",
    setup: ->
      @server = sinon.fakeServer.create()
      @fakeHeaders =
        link: '<http://some_url>; rel="last"'
      fakeENV.setup()
      ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test "calls the resolved endpoint", ->
    @stub($, 'ajaxJSON').returns(new Promise(->))
    api.list()
    ok $.ajaxJSON.calledWith('api/grading_period_sets')

  asyncTest "deserializes returned grading period sets", ->
    @server.respondWith "GET", /grading_period_sets/, [200, {"Content-Type":"application/json", "Link": @fakeHeaders}, JSON.stringify serializedSets]
    api.list()
       .then (sets) =>
          deepEqual sets, deserializedSets
          start()
    @server.respond()

  asyncTest "creates a title from the creation date when the set has no title", ->
    untitledSets =
      grading_period_sets: [
        id: "1"
        title: null
        grading_periods: []
        permissions: { read: true, create: true, update: true, delete: true }
        created_at: "2015-11-29T12:00:00Z"
      ]
    jsonString = JSON.stringify(untitledSets)
    @server.respondWith(
      "GET",
      /grading_period_sets/,
      [200, { "Content-Type":"application/json", "Link": @fakeHeaders }, jsonString]
    )
    api.list()
       .then (sets) =>
          equal sets[0].title, "Set created Nov 29, 2015"
          start()
    @server.respond()

  asyncTest "uses the endDate as the closeDate when a period has no closeDate", ->
    setsWithoutPeriodCloseDate =
      grading_period_sets: [
        id: "1"
        title: "Fall 2015"
        grading_periods: [{
          id: "1",
          title: "Q1",
          start_date: new Date("2015-09-01T12:00:00Z"),
          end_date: new Date("2015-10-31T12:00:00Z"),
          close_date: null
        }]
        permissions: { read: true, create: true, update: true, delete: true }
        created_at: "2015-11-29T12:00:00Z"
      ]
    jsonString = JSON.stringify(setsWithoutPeriodCloseDate)
    @server.respondWith(
      "GET",
      /grading_period_sets/,
      [200, { "Content-Type":"application/json", "Link": @fakeHeaders }, jsonString]
    )
    api.list()
       .then (sets) =>
          deepEqual sets[0].gradingPeriods[0].closeDate, new Date("2015-10-31T12:00:00Z")
          start()
    @server.respond()

  deserializedSetCreating = {
    title: "Fall 2015",
    enrollmentTermIDs: [ "1", "2" ]
  }

  deserializedSetCreated = {
    id: "1",
    title: "Fall 2015",
    gradingPeriods: [],
    enrollmentTermIDs: [ "1", "2" ],
    permissions: { read: true, create: true, update: true, delete: true },
    createdAt: new Date("2015-12-31T12:00:00Z")
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
      permissions: { read: true, create: true, update: true, delete: true },
      created_at: "2015-12-31T12:00:00Z"
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
          end_date: new Date("2015-10-31T12:00:00Z"),
          close_date: new Date("2015-11-07T12:00:00Z")
        },{
          id: "2",
          title: "Q2",
          start_date: new Date("2015-11-01T12:00:00Z"),
          end_date: new Date("2015-12-31T12:00:00Z"),
          close_date: null
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
