define [
  'underscore'
  'Backbone'
  'compiled/views/modules/ModuleItemViewRegister'
],(_, Backbone, ModuleItemViewRegister) ->
  module 'MIVR: Register'
  test 'allows you to render view instances with a look up key', ->
    testView = new Backbone.View
    ModuleItemViewRegister.register key: 'testView', view: testView

    deepEqual ModuleItemViewRegister.views['testView'], testView, "Adds view to the register"
