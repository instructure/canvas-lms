define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Course'
], (PaginatedCollection, Course) ->

  class FavoriteCourseCollection extends PaginatedCollection

    url: '/api/v1/users/self/favorites/courses/'
