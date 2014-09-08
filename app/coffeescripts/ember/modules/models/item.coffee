define [
  'jquery'
  'ember'
  '../lib/store'
  'ic-ajax'
], ($, Ember, store, {request}) ->

  {get, computed} = Ember
  {alias, bool} = computed

  Item = Ember.Object.extend

    error: no

    hasError: bool('error')

    module: (->
      store.find('module', @get('module_id'))
    ).property('module_id')

    pointsPossible: alias('content_details.points_possible')

    due: alias('content_details.due_at')

    serialize: ->
      @getProperties([
        'completion_requirement'
        'content_id'
        'external_url'
        'indent'
        'module_id'
        'new_tab'
        'page_url'
        'position'
        'title'
        'type'
      ])

    save: ->
      @set('isSaving', yes)
      request(
        data: module_item: @serialize()
        type: if @get('id') then 'put' else 'post'
        url: @get('apiUrl')
      ).then ((response) =>
        @setProperties(response)
        @set('isSaving', no)
      ), (=>
        @set('isSaving', no)
        @set('error', on)
      )

    apiUrl: (->
      id = @get('id')
      base = "/api/v1/courses/#{ENV.course_id}/modules/#{@get('module_id')}/items"
      if id then "#{base}/#{id}" else base
    ).property('id')

  Item.reopenClass

    createRecord: (props) ->
      store.push('item', @create(props))

  store.register('item', Item)

