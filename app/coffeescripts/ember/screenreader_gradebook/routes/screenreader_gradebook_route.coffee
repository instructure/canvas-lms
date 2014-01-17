define [
  'ember',
  'ic-ajax',
  '../../shared/xhr/fetch_all_pages'
]
, (Ember, ajax, fetchAllPages) ->

  ScreenreaderGradebookRoute = Ember.Route.extend

    model: ->
      enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.students_url)
      assignment_groups: fetchAllPages(ENV.GRADEBOOK_OPTIONS.assignment_groups_url)
      submissions: Em.ArrayProxy.create(content: [])
      sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
