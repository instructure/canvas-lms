define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/RosterUser'
], (PaginatedCollection, RosterUser) ->

  class RosterUserCollection extends PaginatedCollection

    model: RosterUser

    ##
    # The course id the users belong to

    @optionProperty 'course_id'

    ##
    # A SectionCollection

    @optionProperty 'sections'

    url: ->
      "/api/v1/courses/#{@options.course_id}/users"

