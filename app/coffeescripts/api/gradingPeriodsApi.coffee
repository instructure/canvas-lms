define [
  'jquery'
  'underscore'
  'axios'
  'jquery.instructure_misc_helpers'
], ($, _, axios) ->
  batchUpdateUrl = (id) =>
    $.replaceTags(ENV.GRADING_PERIODS_UPDATE_URL, 'set_id', id)

  serializePeriods = (periods) ->
    serialized = _.map periods, (period) ->
      {
        id: period.id
        title: period.title
        start_date: period.startDate
        end_date: period.endDate
      }
    grading_periods: serialized

  deserializePeriods = (data) ->
    _.map data.grading_periods, (period) ->
      {
        id: period.id
        title: period.title
        startDate: new Date(period.start_date)
        endDate: new Date(period.end_date)
      }

  batchUpdate: (setId, periods) ->
    promise = new Promise (resolve, reject) =>
      axios.patch(batchUpdateUrl(setId), serializePeriods(periods))
           .then (response) ->
             resolve(deserializePeriods(response.data))
           .catch (error) ->
             reject(error)
    promise
