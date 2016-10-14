define [
  'jquery'
  'underscore'
  'i18n!grading_periods'
  'jsx/shared/helpers/dateHelper'
  'axios'
  'jsx/gradebook2/CheatDepaginator'
  'jquery.instructure_misc_helpers'
], ($, _, I18n, DateHelper, axios, Depaginate) ->
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
        id: period.id.toString()
        title: period.title
        startDate: new Date(period.start_date)
        endDate: new Date(period.end_date)
        # TODO: After the close_date data fixup has run, this can become:
        # `closeDate: new Date(period.close_date)`
        closeDate: new Date(period.close_date || period.end_date)
      }

  baseDeserializeSet = (set) ->
    {
      id: set.id.toString()
      title: gradingPeriodSetTitle(set)
      gradingPeriods: deserializePeriods(set.grading_periods)
      permissions: set.permissions
      createdAt: new Date(set.created_at)
    }

  gradingPeriodSetTitle = (set) ->
    if set.title?.trim()
      set.title.trim()
    else
      createdAt = DateHelper.formatDateForDisplay(new Date(set.created_at))
      I18n.t("Set created %{createdAt}", { createdAt: createdAt });

  deserializeSet = (set) ->
    newSet = baseDeserializeSet(set)
    newSet.enrollmentTermIDs = set.enrollment_term_ids
    newSet

  deserializeSets = (setGroups) ->
    _.flatten _.map setGroups, (group) ->
      _.map group.grading_period_sets, (set) -> baseDeserializeSet(set)

  list: () ->
    promise = new Promise (resolve, reject) =>
      Depaginate(listUrl())
           .then (response) ->
             resolve(deserializeSets(response))
           .fail (error) ->
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
