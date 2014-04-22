define [
  'ember',
  'underscore',
  'ic-ajax',
  '../../shared/xhr/fetch_all_pages'
]
, ({Route, ArrayProxy}, _, ajax, fetchAllPages) ->

  ScreenreaderGradebookRoute = Route.extend

    model: ->
      enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.students_url)
      assignment_groups: fetchAllPages(ENV.GRADEBOOK_OPTIONS.assignment_groups_url)
      submissions: ArrayProxy.create(content: [])
      custom_columns: fetchAllPages(ENV.GRADEBOOK_OPTIONS.custom_columns_url)
      sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
      outcomes: fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_links_url, process: (response) ->
        response.map((x) -> x.outcome)
      )
      outcome_rollups: fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_rollups_url, process: (response) ->
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
