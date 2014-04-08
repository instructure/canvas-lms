define [
  'ember'
  'ic-lazy-list'
  '../models/module'
], (Ember, LazyListComponent, Module) ->

  ModuleListComponent = LazyListComponent.extend

    href: "/api/v1/courses/#{ENV.course_id}/modules?include[]=items"

    normalize: ({response}) ->
      (Module.createRecord(module) for module in response)

