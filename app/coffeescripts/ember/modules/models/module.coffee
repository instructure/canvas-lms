define [
  'ember'
  '../lib/store'
  'ic-ajax'
], (Ember, store, ajax) ->

  {computed} = Ember

  Module = Ember.Object.extend

    serialize: ->
      @getProperties([
        'name'
        'unlock_at'
        'position'
        'require_sequential_progress'
        'prerequisite_module_ids'
        'publish_final_grade'
      ])

    url: (->
      id = @get('id')
      base = @constructor.baseUrl
      if id then "#{base}/#{id}" else base
    ).property('id')

    save: ->
      @set('isSaving', yes)
      ajax.raw(
        data: module: @serialize()
        type: if @get('id') then 'put' else 'post'
        url: @get('url')
      ).then (({response}) =>
        @setProperties(response)
        @set('isSaving', no)
      ), (=>
        @set('isSaving', no)
        @set('saveError', yes)
      )

    destroy: ->
      @set('isDestroying', yes)
      ajax.raw(
        type: 'delete'
        url: @get('url')
      ).then (({response}) =>
        @set('isDestroying', no)
      ), (=>
        @set('isDestroying', no)
        @set('destroyError', yes)
      )


    locked: computed.bool('unlock_at')

    itemsWithContentUrl: (->
      "#{@get('items_url')}?include[]=content_details"
    ).property('items_url')

  Module.reopenClass

    baseUrl: "/api/v1/courses/#{ENV.course_id}/modules"

    createRecord: (props) ->
      @createItems(props) if props.items
      module = @create(props)
      module.save() unless props.id
      store.push('module', module)

    createItems: (props) ->
      Item = store.lookup('item')
      props.items = (Item.createRecord(item) for item in props.items)

  store.register('module', Module)

