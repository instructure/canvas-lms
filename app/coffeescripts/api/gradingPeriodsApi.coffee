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
        close_date: period.closeDate
        weight: period.weight
      }
    grading_periods: serialized

  deserializePeriods: (periods) ->
    _.map periods, (period) ->
      {
        id: period.id
        title: period.title
        startDate: new Date(period.start_date)
        endDate: new Date(period.end_date)
        closeDate: new Date(period.close_date)
        isLast: period.is_last
        isClosed: period.is_closed
        weight: period.weight
      }

  batchUpdate: (setId, periods) ->
    promise = new Promise (resolve, reject) =>
      axios.patch(batchUpdateUrl(setId), serializePeriods(periods))
           .then (response) =>
             resolve(@deserializePeriods(response.data.grading_periods))
           .catch (error) ->
             reject(error)
    promise
