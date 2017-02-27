define [
  'compiled/collections/ModuleCollection'
], (ModuleCollection) ->
  QUnit.module 'ModuleCollection',

  test "generates the correct fetch url", ->
    course_id = 5

    collection = new ModuleCollection [],
      course_id: course_id
    equal collection.url(), "/api/v1/courses/#{course_id}/modules"