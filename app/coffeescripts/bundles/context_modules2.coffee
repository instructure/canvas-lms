require [
  'jquery'
  'compiled/collections/ModuleCollection',
  'compiled/views/modules/ModuleCollectionView',
], ($, ModuleCollection, ModuleCollectionView) ->

  $(document.body).addClass 'context_modules2'

  modules = new ModuleCollection null,
    course_id: ENV.COURSE_ID
  modules.fetch({data: {include: ['items']}})

  modulesView = new ModuleCollectionView
    editable: ENV.CAN_MANAGE_MODULES
    collection: modules
    el: '#modules'

  modulesView.render()