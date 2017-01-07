define [
  'ember',
  'jquery',
  'underscore',
  'ic-ajax',
  '../../shared/xhr/fetch_all_pages'
]
, ({Route, ArrayProxy, ObjectProxy, set}, $, _, ajax, fetchAllPages) ->

  ScreenreaderGradebookRoute = Route.extend

    model: ->
      model =
        enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.enrollments_url)
        assignment_groups: ArrayProxy.create(content: [])
        submissions: ArrayProxy.create(content: [])
        custom_columns: fetchAllPages(ENV.GRADEBOOK_OPTIONS.custom_columns_url)
        sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
        effectiveDueDates: ObjectProxy.create(content: {})

      $.ajaxJSON(ENV.GRADEBOOK_OPTIONS.effective_due_dates_url, "GET").then (result) =>
        data = ObjectProxy.create(content: result)
        data.set('isLoaded', true)
        set(model, 'effectiveDueDates', data)

      if !ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
        model.outcomes = model.outcome_rollups = ArrayProxy.create({content: []})
      else
        model.outcomes = fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_links_url, process: (response) ->
          response.map((x) -> x.outcome)
        )
        model.outcome_rollups =  fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_rollups_url, process: (response) ->
          _.flatten(response.rollups.map((row) ->
            row.scores.map((cell) ->
              {
                user_id: row.links.user
                outcome_id: cell.links.outcome
                score: cell.score
              }
            )
          ))
        )

      model
