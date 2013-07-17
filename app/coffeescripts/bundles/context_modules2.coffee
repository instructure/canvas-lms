require [
  'jquery'
  'compiled/collections/ModuleCollection',
  'compiled/views/modules/ModuleCollectionView',
], ($, ModuleCollection, ModuleCollectionView) ->

  modules = new ModuleCollection null,
    course_id: ENV.COURSE_ID
  modules.fetch({data: {include: ['items']}})

  modulesView = new ModuleCollectionView
    collection: modules
    el: '#modules'

  modulesView.render()

