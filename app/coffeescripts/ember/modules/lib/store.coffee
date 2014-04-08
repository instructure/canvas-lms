define [
  'ember'
  'ic-ajax'
], (Ember, {request}) ->

  # TODO: move all server code here, and not have vague types, but actually
  # register them here too

  {get, set} = Ember

  @store =

    courseId: ENV.course_id

    types: {}

    cache: {}

    register: (type, def) ->
      @types[type] = def
      @cache[type] = {}
      def

    lookup: (type) ->
      @types[type]

    push: (type, model) ->
      @cache[type][get(model, 'id')] = model

    find: (type, id) ->
      @cache[type][id]

    moveItem: (item, newModuleId, index) ->
      targetModule = @find('module', newModuleId)
      oldModule = @find('module', item.module_id)
      get(oldModule, 'items').removeObject(item)
      set(item, 'module_id', newModuleId)
      get(targetModule, 'items').insertAt(index, item)

    syncModuleItemsOrder: (id) ->
      module = @find('module', id)
      items = get(module, 'items')
      ids = items.mapBy('id').join(',')
      request
        url: "/courses/#{@courseId}/modules/#{id}/reorder"
        data: {order: ids}
        type: 'post'

    syncItemById: (id) ->
      item = @find('item', id)
      request
        url: "/api/v1/courses/#{@courseId}/modules/#{item.module_id}/items/#{id}"
        data: {module_item: item.serialize()}
        type: 'put'

