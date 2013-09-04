define [
  'ember'
  '../models/module'
  '../models/module_item'
], (Ember, Module, ModuleItem) ->
  Ember.Route.extend
    model: ->
      Module.findAll window.ENV.COURSE_ID
      # Module.findAll(window.ENV.COURSE_ID)
    events:
      showAddModuleModal: ->
        this.modelFor('index').unshiftObject(Ember.Object.create(
          name: 'Unnamed'
        ))
        # this.controllerFor('reveal').set('model',awefwae)
