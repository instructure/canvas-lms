require [
  'jquery',
  'compiled/collections/ModuleCollection',
  'compiled/views/modules/ModuleCollectionView',
  'compiled/views/modules/ModuleItemViewRegister'
  'compiled/views/modules/item_types/SelectFileView'
], ($, ModuleCollection, ModuleCollectionView, ModuleItemViewRegister, SelectFileView) ->

  $(document.body).addClass 'context_modules2'

  modules = new ModuleCollection null,
    course_id: ENV.COURSE_ID
  modules.fetch({data: {include: ['items']}})

  modulesView = new ModuleCollectionView
    editable: ENV.CAN_MANAGE_MODULES
    collection: modules
    el: '#modules'
 
  ModuleItemViewRegister.register
                          key: 'File'
                          view: new SelectFileView
  modulesView.render()
