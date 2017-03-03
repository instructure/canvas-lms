define [
  'underscore',
  'axios',
  'helpers/fakeENV',
  'compiled/api/gradingPeriodsApi'
], (_, axios, fakeENV, api) ->
  deserializedPeriods = [
    {
      id: '1',
      title: 'Q1',
      startDate: new Date('2015-09-01T12:00:00Z'),
      endDate: new Date('2015-10-31T12:00:00Z'),
      closeDate: new Date('2015-11-07T12:00:00Z'),
      isClosed: true,
      isLast: false,
      weight: 40
    },{
      id: '2',
      title: 'Q2',
      startDate: new Date('2015-11-01T12:00:00Z'),
      endDate: new Date('2015-12-31T12:00:00Z'),
      closeDate: new Date('2016-01-07T12:00:00Z'),
      isClosed: true,
      isLast: true,
      weight: 60
    }
  ]

  serializedPeriods = {
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
        close_date: new Date('2016-01-07T12:00:00Z'),
        weight: 60
      }
    ]
  }

  periodsData = {
    grading_periods: [
      {
        id: '1',
        title: 'Q1',
        start_date: '2015-09-01T12:00:00Z',
        end_date: '2015-10-31T12:00:00Z',
        close_date: '2015-11-07T12:00:00Z',
        is_closed: true,
        is_last: false,
        weight: 40
      },{
        id: '2',
        title: 'Q2',
        start_date: '2015-11-01T12:00:00Z',
        end_date: '2015-12-31T12:00:00Z',
        close_date: '2016-01-07T12:00:00Z',
        is_closed: true,
        is_last: true,
        weight: 60
      }
    ]
  }

  QUnit.module 'batchUpdate',
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIODS_UPDATE_URL = 'api/{{ set_id }}/batch_update'
    teardown: ->
      fakeENV.teardown()

  test 'calls the resolved endpoint with serialized grading periods', ->
    apiSpy = @stub(axios, 'patch').returns(new Promise(->))
    api.batchUpdate(123, deserializedPeriods)
    ok axios.patch.calledWith('api/123/batch_update', serializedPeriods)

  test 'deserializes returned grading periods', ->
    @stub(axios, 'patch').returns(Promise.resolve({ data: periodsData }))
    api.batchUpdate(123, deserializedPeriods)
      .then (periods) =>
        deepEqual periods, deserializedPeriods

  test 'rejects the promise upon errors', ->
    @stub(axios, 'patch').returns(Promise.reject('FAIL'))
    api.batchUpdate(123, deserializedPeriods)
      .catch (error) =>
        equal error, 'FAIL'

  QUnit.module 'deserializePeriods'

  test 'returns an empty array if passed undefined', ->
    propEqual api.deserializePeriods(undefined), []

  test 'returns an empty array if passed null', ->
    propEqual api.deserializePeriods(null), []

  test 'deserializes periods', ->
    result = api.deserializePeriods(periodsData.grading_periods)
    propEqual result, deserializedPeriods
