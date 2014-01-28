define [
  'ember',
  'ic-ajax',
  '../../shared/xhr/fetch_all_pages',
  'underscore'
]
, (Ember, ajax, fetchAllPages, _) ->

  ScreenreaderGradebookRoute = Ember.Route.extend

    model: ->
      #TODO figure out why submissions isn't paginating
      enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.students_url)
      assignment_groups: fetchAllPages(ENV.GRADEBOOK_OPTIONS.assignment_groups_url)
      submissions: fetchAllPages(ENV.GRADEBOOK_OPTIONS.submissions_url, student_ids: 'all')
      sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
