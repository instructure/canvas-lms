define [
  'jquery'
  'underscore'
  'axios'
  'jquery.instructure_misc_helpers'
], ($, _, axios) ->
  listUrl = () =>
    ENV.GRADING_PERIOD_SETS_URL

  createUrl = () =>
    ENV.GRADING_PERIOD_SETS_URL

  updateUrl = (id) =>
    $.replaceTags(ENV.GRADING_PERIOD_SET_UPDATE_URL, 'id', id)

  serializeSet = (set) =>
    grading_period_set: { title: set.title },
    enrollment_term_ids: set.enrollmentTermIDs

  deserializePeriods = (periods) =>
    _.map periods, (period) ->
      {
        id: period.id
        title: period.title
        startDate: new Date(period.start_date)
        endDate: new Date(period.end_date)
      }

  deserializeSet = (set) ->
    {
      id: set.id
      title: set.title
      enrollmentTermIDs: set.enrollment_term_ids
      gradingPeriods: deserializePeriods(set.grading_periods)
      permissions: set.permissions
    }

  deserializeSets = (data) ->
    _.map data.grading_period_sets, (set) ->
      {
        id: set.id
        title: set.title
        gradingPeriods: deserializePeriods(set.grading_periods)
        permissions: set.permissions
      }

  list: () ->
    promise = new Promise (resolve, reject) =>
      axios.get(listUrl())
           .then (response) ->
             resolve(deserializeSets(response.data))
           .catch (error) ->
             reject(error)
    promise

  create: (set) ->
    promise = new Promise (resolve, reject) =>
      axios.post(createUrl(), serializeSet(set))
           .then (response) ->
             resolve(deserializeSet(response.data.grading_period_set))
           .catch (error) ->
             reject(error)
    promise

  update: (set) ->
    promise = new Promise (resolve, reject) =>
      axios.patch(updateUrl(set.id), serializeSet(set))
           .then (response) ->
             resolve(set)
           .catch (error) ->
             reject(error)
    promise
