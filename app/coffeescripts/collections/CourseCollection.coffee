define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Course'
], (PaginatedCollection, Course) ->

  class CourseCollection extends PaginatedCollection
    url: '/api/v1/courses/'

    initialize: () ->
      super()
      @setParam('state', ['unpublished', 'available', 'completed'])
