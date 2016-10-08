define [
  'underscore',
  'axios',
  'helpers/fakeENV',
  'compiled/api/gradingPeriodsApi'
], (_, axios, fakeENV, api) ->
  deserializedPeriods = [
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
  ]

  serializedPeriods = {
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
    ]
  }

  module "batchUpdate",
    setup: ->
      fakeENV.setup()
      ENV.GRADING_PERIODS_UPDATE_URL = 'api/{{ set_id }}/batch_update'
    teardown: ->
      fakeENV.teardown()

  test "calls the resolved endpoint with serialized grading periods", ->
    apiSpy = @stub(axios, "patch").returns(new Promise(->))
    api.batchUpdate(123, deserializedPeriods)
    ok axios.patch.calledWith('api/123/batch_update', serializedPeriods)

  asyncTest "deserializes returned grading periods", ->
    successPromise = new Promise (resolve) => resolve({ data: serializedPeriods })
    @stub(axios, "patch").returns(successPromise)
    api.batchUpdate(123, deserializedPeriods)
       .then (periods) =>
          deepEqual periods, deserializedPeriods
          start()

  asyncTest "uses the endDate as the closeDate when a period has no closeDate", ->
    periodsWithoutCloseDate = {
      grading_periods: [
        {
          id: "1",
          title: "Q1",
          start_date: new Date("2015-09-01T12:00:00Z"),
          end_date: new Date("2015-10-31T12:00:00Z"),
          close_date: null
        }
      ]
    }
    successPromise = new Promise (resolve) => resolve({ data: periodsWithoutCloseDate })
    @stub(axios, "patch").returns(successPromise)
    api.batchUpdate(123, deserializedPeriods)
       .then (periods) =>
          deepEqual periods[0].closeDate, new Date("2015-10-31T12:00:00Z")
          start()

  asyncTest "rejects the promise upon errors", ->
    failurePromise = new Promise (_, reject) => reject("FAIL")
    @stub(axios, "patch").returns(failurePromise)
    api.batchUpdate(123, deserializedPeriods).catch (error) =>
      equal error, "FAIL"
      start()
