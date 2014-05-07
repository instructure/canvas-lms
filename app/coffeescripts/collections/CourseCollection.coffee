define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Course'
], (PaginatedCollection, Course) ->

  class CourseCollection extends PaginatedCollection
    url: '/api/v1/courses/'
    loadAll: true
    initialize: () ->
      super()
      @setParam('state', ['unpublished', 'available', 'completed'])
      @setParam('include', ['term'])
