define [
  'ember'
  '../models/module'
  'ic-ajax'
  '../lib/store'
], (Ember, Module, {request}, store) ->

  ModulesController = Ember.Controller.extend

    newModule: { name: 'Noname'}

    modules: []

    actions:

      moveItem: (item, moduleId, index) ->
        store.moveItem(item, moduleId, index)
        store.syncModuleItemsOrder(moduleId)

      syncModulesOrder: (ids) ->
        url = "/courses/#{ENV.course_id}/modules/reorder"
        data = {order: ids.join(',')}
        request({
          url: url
          data: data
          type: 'post'
        }).then (modules) ->
          for item in modules
            {position, id} = item.context_module
            store.find('module', id).set('position', position)

      createModule: ->
        newModule = Module.createRecord(@get('newModule'))
        newModule.set('isNew', true)
        @get('modules').addObject(newModule)
        @set('newModule', {})

