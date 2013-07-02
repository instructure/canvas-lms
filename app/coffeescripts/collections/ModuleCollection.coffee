define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Module'
], (PaginatedCollection, Module) ->

  class ModuleCollection extends PaginatedCollection
    model: Module

    @optionProperty 'course_id'

    url: -> "/api/v1/courses/#{@course_id}/modules"