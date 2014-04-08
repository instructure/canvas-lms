define [
  'ember'
  'ic-sortable'
  'jquery'
  'ic-droppable'
  '../lib/accepts_drop_mixin'
], (Ember, Sortable, $, Droppable, AcceptsDrop) ->

  Droppable = Droppable.default

  MmSortableModuleItemComponent = Ember.Component.extend Sortable.default, AcceptsDrop,

    accepts: ['text/ic-module-item']

    # let the .sortable-handle draggable bubble up to here
    draggable: 'false'

    tagName: 'li'

    classNames: ['context_module_item']

    setEventData: (event) ->
      @makeGhost(event)
      event.dataTransfer.setData('text/ic-module-item', @get('item.id'))

    makeGhost: (event) ->
      rect = @get('element').getBoundingClientRect()
      x = event.originalEvent.clientX - rect.left
      y = event.originalEvent.clientY - rect.top
      event.dataTransfer.setDragImage(this.get('element'), x, y)

    'accept:text/ic-module-item': (event, data) ->
      droppedItem = store.find('item', data)
      droppedItemMovedModules = @get('item.module_id') isnt droppedItem.module_id
      if droppedItemMovedModules
        index = @get('item.module.items').indexOf(@get('item'))
        index = index + 1 if @get('droppedPosition') is 'after'
        @sendAction('on-receive-item-from-other-module', droppedItem, @get('item.module_id'), index)
      else
        @sendAction('on-reorder-item', droppedItem, @get('item'), @get('droppedPosition'))

