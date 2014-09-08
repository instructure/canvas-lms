define ['ember'], (Ember) ->

  # TODO: figure out something better than this hack to be able to link
  # ic-actions to ic-modal in the template with return-focus-to. Doing
  # it this way because we need an ID before the model is saved, and we don't
  # know the ember auto generated view id in the template because we have no
  # way to reference one to the other (that's the whole point of this!)
  cid = -1

  ModuleController = Ember.ObjectController.extend

    needs: ['modules']

    cid: (-> ++cid).property()

    setMakeLazyList: (->
      @set('makeLazyList', !@get('items') && @get('items_count') > 0)
    ).on('init')

    formId: (->
      "edit-module-#{@get('cid')}"
    ).property('id')

    actionsId: (->
      # branch here to focus the new module
      "module-actions-#{@get('cid')}"
    ).property()

    actions:

      reorderItem: (droppedItem, targetItem, droppedPosition) ->
        items = @get('items')
        items.removeObject(droppedItem)
        index = items.indexOf(targetItem)
        index = index + 1 if droppedPosition is 'after'
        items.insertAt(index, droppedItem)
        store.syncModuleItemsOrder(@get('id'))

      edit: (menuItem) ->
        @set('modelBeforeEdits', @get('model').serialize())
        Ember.View.views[@get('formId')].open()

      delete: ->
        @set('isDeleting', true)
        Ember.run.later this, ->
          model = @get('model')
          @get('controllers.modules.modules').removeObject(model)
          model.destroy()
        , 200 # animation time

      restoreModel: ->
        @get('model').setProperties(@get('modelBeforeEdits'))

      saveEdits: ->
        @get('model').save()

