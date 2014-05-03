define [
  'ember',
  'ic-ajax',
  '../../shared/xhr/fetch_all_pages'
]
, ({Route, ArrayProxy}, ajax, fetchAllPages) ->

  ScreenreaderGradebookRoute = Route.extend

    model: ->
      enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.students_url)
      assignment_groups: fetchAllPages(ENV.GRADEBOOK_OPTIONS.assignment_groups_url)
      submissions: ArrayProxy.create(content: [])
      custom_columns: fetchAllPages(ENV.GRADEBOOK_OPTIONS.custom_columns_url)
      sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
