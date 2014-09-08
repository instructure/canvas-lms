define [
  'ember'
  'ic-sortable'
  'jquery'
  'ic-droppable'
  '../lib/accepts_drop_mixin'
  '../lib/store'
], (Ember, Sortable, $, Droppable, AcceptsDrop, store) ->

  Droppable = Droppable.default

  MmSortableModuleComponent = Ember.Component.extend Sortable.default, AcceptsDrop,

    accepts: ['text/ic-module', 'text/ic-module-item']

    classNameBindings: ['locked', 'acceptTypeClassName']

    classNames: ['item-group-condensed']

    acceptTypeClassName: (->
      type = @get('accept-type')
      return unless type
      type.replace(/\//, '-')
    ).property('accept-type')

    locked: (->
      @get('module.locked')
    ).property('module.locked')

    # let the .sortable-handle draggable bubble up to here
    draggable: 'false'

    setEventData: (event) ->
      @makeGhost(event)
      event.dataTransfer.setData('text/ic-module', @get('module.id'))

    makeGhost: (event) ->
      rect = @get('element').getBoundingClientRect()
      x = event.originalEvent.clientX - rect.left
      ghost = $('<div class="module-ghost"/>')
      ghost.html(@get('module.name'))
      ghost.appendTo(document.body)
      event.dataTransfer.setDragImage(ghost[0], x, 10)
      Ember.run.later(ghost, 'remove', 0)

    isSelfDrop: (event) ->
      thisElement = @$()
      thisElement.has(Droppable._currentDrag).length > 0

    validateDragEvent: (event) ->
      types = event.dataTransfer.types
      return off if types.contains('text/ic-module') and @isSelfDrop(event)
      return no if types.contains('text/ic-module-item') and @get('module.items.length') isnt 0
      @_super(event)

    'accept:text/ic-module': (event, id) ->
      modules = @get('modules')
      droppedModule = modules.findBy('id', parseInt(id, 10))
      modules.removeObject(droppedModule)
      index = modules.indexOf(@get('module'))
      index = index + 1 if @get('droppedPosition') is 'after'
      modules.insertAt(index, droppedModule)
      @sendAction('on-reorder', modules.mapBy('id'))

    'accept:text/ic-module-item': (event, data) ->
      droppedItem = store.find('item', data)
      module = store.find('module', droppedItem.module_id)
      module.items.removeObject(droppedItem)
      droppedItem.module_id = @get('module.id')
      @get('module.items').addObject(droppedItem)
      store.syncModuleItemsOrder(@get('module.id'))

