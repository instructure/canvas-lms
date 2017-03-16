define [
  'jquery'
  'underscore'
  'i18n!grading_periods'
  'jsx/shared/helpers/dateHelper'
  'compiled/api/gradingPeriodsApi'
  'axios'
  'jsx/shared/CheatDepaginator'
  'jquery.instructure_misc_helpers'
], ($, _, I18n, DateHelper, gradingPeriodsApi, axios, Depaginate) ->
  listUrl = () =>
    ENV.GRADING_PERIOD_SETS_URL

  createUrl = () =>
    ENV.GRADING_PERIOD_SETS_URL

  updateUrl = (id) =>
    $.replaceTags(ENV.GRADING_PERIOD_SET_UPDATE_URL, 'id', id)

  serializeSet = (set) =>
    gradingPeriodSetAttrs =
      title: set.title
      weighted: set.weighted
      display_totals_for_all_grading_periods: set.displayTotalsForAllGradingPeriods
    grading_period_set: gradingPeriodSetAttrs
    enrollment_term_ids: set.enrollmentTermIDs

  baseDeserializeSet = (set) ->
    {
      id: set.id.toString()
      title: gradingPeriodSetTitle(set)
      weighted: !!set.weighted
      displayTotalsForAllGradingPeriods: set.display_totals_for_all_grading_periods
      gradingPeriods: gradingPeriodsApi.deserializePeriods(set.grading_periods)
      permissions: set.permissions
      createdAt: new Date(set.created_at)
    }

  gradingPeriodSetTitle = (set) ->
    if set.title?.trim()
      set.title.trim()
    else
      createdAt = DateHelper.formatDateForDisplay(new Date(set.created_at))
      I18n.t('Set created %{createdAt}', { createdAt })

  deserializeSet = (set) ->
    newSet = baseDeserializeSet(set)
    newSet.enrollmentTermIDs = set.enrollment_term_ids
    newSet

  deserializeSets = (setGroups) ->
    _.flatten _.map setGroups, (group) ->
      _.map group.grading_period_sets, (set) -> baseDeserializeSet(set)

  deserializeSet: deserializeSet

  list: () ->
    promise = new Promise (resolve, reject) =>
      Depaginate(listUrl())
        .then (response) ->
          resolve(deserializeSets(response))
        .fail (error) ->
          reject(error)
    promise

  create: (set) ->
    axios.post(createUrl(), serializeSet(set))
      .then (response) ->
        deserializeSet(response.data.grading_period_set)

  update: (set) ->
    axios.patch(updateUrl(set.id), serializeSet(set))
      .then (response) ->
        set
