define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/ModuleItem'
], (PaginatedCollection, ModuleItem) ->

  class ModuleItemCollection extends PaginatedCollection
    model: ModuleItem

    @optionProperty 'course_id'
    @optionProperty 'module_id'

    url: -> "/api/v1/courses/#{@course_id}/modules/#{@module_id}/items"