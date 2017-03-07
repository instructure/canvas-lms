define [
  'axios'
  'helpers/fakeENV',
  'compiled/api/gradingPeriodSetsApi'
], (axios, fakeENV, api) ->
  deserializedSets = [
    {
      id: '1',
      title: 'Fall 2015',
      weighted: false,
      displayTotalsForAllGradingPeriods: false,
      gradingPeriods: [
        {
          id: '1',
          title: 'Q1',
          startDate: new Date('2015-09-01T12:00:00Z'),
          endDate: new Date('2015-10-31T12:00:00Z'),
          closeDate: new Date('2015-11-07T12:00:00Z'),
          isClosed: true,
          isLast: false,
          weight: 43.5
        },{
          id: '2',
          title: 'Q2',
          startDate: new Date('2015-11-01T12:00:00Z'),
          endDate: new Date('2015-12-31T12:00:00Z'),
          closeDate: new Date('2016-01-07T12:00:00Z'),
          isClosed: false,
          isLast: true,
          weight: null
        }
      ],
      permissions: { read: true, create: true, update: true, delete: true },
      createdAt: new Date('2015-12-29T12:00:00Z')
    },{
      id: '2',
      title: 'Spring 2016',
      weighted: true,
      displayTotalsForAllGradingPeriods: false,
      gradingPeriods: [],
      permissions: { read: true, create: true, update: true, delete: true },
      createdAt: new Date('2015-11-29T12:00:00Z')
    }
  ]

  serializedSets = {
    grading_period_sets: [
      {
        id: '1',
        title: 'Fall 2015',
        weighted: false,
        display_totals_for_all_grading_periods: false,
        grading_periods: [
          {
            id: '1',
            title: 'Q1',
            start_date: new Date('2015-09-01T12:00:00Z'),
            end_date: new Date('2015-10-31T12:00:00Z'),
            close_date: new Date('2015-11-07T12:00:00Z'),
            is_closed: true,
            is_last: false,
            weight: 43.5
          },{
            id: '2',
            title: 'Q2',
            start_date: new Date('2015-11-01T12:00:00Z'),
            end_date: new Date('2015-12-31T12:00:00Z'),
            close_date: new Date('2016-01-07T12:00:00Z'),
            is_closed: false,
            is_last: true,
            weight: null
          }
        ],
        permissions: { read: true, create: true, update: true, delete: true },
        created_at: '2015-12-29T12:00:00Z'
      },
      {
        id: '2',
        title: 'Spring 2016',
        weighted: true,
        display_totals_for_all_grading_periods: false,
        grading_periods: [],
        permissions: { read: true, create: true, update: true, delete: true },
        created_at: '2015-11-29T12:00:00Z'
      }
    ]
  }

  QUnit.module 'gradingPeriodSetsApi.list',
    setup: ->
      @server = sinon.fakeServer.create()
      @fakeHeaders =
        link: '<http://some_url>; rel="last"'
      fakeENV.setup()
      ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test 'calls the resolved endpoint', ->
    @stub($, 'ajaxJSON').returns(new Promise(->))
    api.list()
    ok $.ajaxJSON.calledWith('api/grading_period_sets')

  test 'deserializes returned grading period sets', ->
    @server.respondWith(
      'GET',
      /grading_period_sets/,
      [200, {'Content-Type':'application/json', 'Link': @fakeHeaders}, JSON.stringify serializedSets]
    )
    @server.autoRespond = true
    promise = api.list()
      .then (sets) =>
        deepEqual sets, deserializedSets

  test 'creates a title from the creation date when the set has no title', ->
    untitledSets =
      grading_period_sets: [
        id: '1'
        title: null
        grading_periods: []
        permissions: { read: true, create: true, update: true, delete: true }
        created_at: '2015-11-29T12:00:00Z'
      ]
    jsonString = JSON.stringify(untitledSets)
    @server.respondWith(
      'GET',
      /grading_period_sets/,
      [200, { 'Content-Type':'application/json', 'Link': @fakeHeaders }, jsonString]
    )
    @server.autoRespond = true
    api.list()
      .then (sets) =>
        equal sets[0].title, 'Set created Nov 29, 2015'

  deserializedSetCreating = {
    title: 'Fall 2015',
    weighted: null,
    displayTotalsForAllGradingPeriods: false,
    enrollmentTermIDs: ['1', '2']
  }

  deserializedSetCreated = {
    id: '1',
    title: 'Fall 2015',
    weighted: false,
    displayTotalsForAllGradingPeriods: false,
    gradingPeriods: [],
    enrollmentTermIDs: ['1', '2'],
    permissions: { read: true, create: true, update: true, delete: true },
    createdAt: new Date('2015-12-31T12:00:00Z')
  }

  serializedSetCreating = {
    grading_period_set: { title: 'Fall 2015', weighted: null, display_totals_for_all_grading_periods: false },
    enrollment_term_ids: ['1', '2']
  }

  serializedSetCreated = {
    grading_period_set: {
      id: '1',
      title: 'Fall 2015',
      weighted: false,
      display_totals_for_all_grading_periods: false,
      enrollment_term_ids: ['1', '2'],
      grading_periods: [],
      permissions: { read: true, create: true, update: true, delete: true },
      created_at: '2015-12-31T12:00:00Z'
    }
  }

  QUnit.module 'gradingPeriodSetsApi.create',
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
    teardown: ->
      fakeENV.teardown()

  test 'calls the resolved endpoint with the serialized grading period set', ->
    apiSpy = @stub(axios, 'post').returns(new Promise(->))
    api.create(deserializedSetCreating)
    ok axios.post.calledWith('api/grading_period_sets', serializedSetCreating)

  test 'deserializes returned grading period sets', ->
    successPromise = new Promise (resolve) => resolve({ data: serializedSetCreated })
    @stub(axios, 'post').returns(successPromise)
    api.create(deserializedSetCreating)
      .then (set) =>
        deepEqual set, deserializedSetCreated

  test 'rejects the promise upon errors', ->
    @stub(axios, 'post').returns(Promise.reject('FAIL'))
    api.create(deserializedSetCreating).catch (error) =>
      equal error, 'FAIL'

  deserializedSetUpdating = {
    id: '1',
    title: 'Fall 2015',
    weighted: true,
    displayTotalsForAllGradingPeriods: true,
    enrollmentTermIDs: ['1', '2'],
    permissions: { read: true, create: true, update: true, delete: true }
  }

  serializedSetUpdating = {
    grading_period_set: { title: 'Fall 2015', weighted: true, display_totals_for_all_grading_periods: true },
    enrollment_term_ids: ['1', '2']
  }

  serializedSetUpdated = {
    grading_period_set: {
      id: '1',
      title: 'Fall 2015',
      weighted: true,
      display_totals_for_all_grading_periods: true,
      enrollment_term_ids: ['1', '2'],
      grading_periods: [
        {
          id: '1',
          title: 'Q1',
          start_date: new Date('2015-09-01T12:00:00Z'),
          end_date: new Date('2015-10-31T12:00:00Z'),
          close_date: new Date('2015-11-07T12:00:00Z'),
          weight: 40
        },{
          id: '2',
          title: 'Q2',
          start_date: new Date('2015-11-01T12:00:00Z'),
          end_date: new Date('2015-12-31T12:00:00Z'),
          close_date: null,
          weight: 60
        }
      ],
      permissions: { read: true, create: true, update: true, delete: true }
    }
  }

  QUnit.module 'gradingPeriodSetsApi.update',
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIOD_SET_UPDATE_URL = 'api/grading_period_sets/%7B%7B%20id%20%7D%7D'
    teardown: ->
      fakeENV.teardown()

  test 'calls the resolved endpoint with the serialized grading period set', ->
    apiSpy = @stub(axios, 'patch').returns(new Promise(->))
    api.update(deserializedSetUpdating)
    ok axios.patch.calledWith('api/grading_period_sets/1', serializedSetUpdating)

  test 'returns the given grading period set', ->
    @stub(axios, 'patch').returns(Promise.resolve({ data: serializedSetUpdated }))
    api.update(deserializedSetUpdating)
       .then (set) =>
          deepEqual set, deserializedSetUpdating

  test 'rejects the promise upon errors', ->
    @stub(axios, 'patch').returns(Promise.reject('FAIL'))
    api.update(deserializedSetUpdating)
      .catch (error) =>
        equal error, 'FAIL'
