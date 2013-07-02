define [
  'compiled/collections/ModuleItemCollection'
], (ModuleItemCollection) ->
  module 'ModuleItemCollection',

  test "generates the correct fetch url", ->
    course_id = 5
    module_id = 10

    collection = new ModuleItemCollection [],
      course_id: course_id
      module_id: module_id
    equal collection.url(), "/api/v1/courses/#{course_id}/modules/#{module_id}/items"