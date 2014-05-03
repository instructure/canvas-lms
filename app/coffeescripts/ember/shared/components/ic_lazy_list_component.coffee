define [
  '../register'
  'ember'
  '../../shared/xhr/parse_link_header'
  'underscore'
  '../templates/components/ic-lazy-list'
], (register, Ember, parseLinkHeader, {throttle}) ->

  $window = Ember.$ window

  IcLazyList = Ember.Component.extend

    tagName: 'ic-lazy-list'

    registerWithConstructor: (->
      @constructor.register this if @get 'meta.next'
    ).observes('meta.next')

    unregisterFromConstructor: (->
      @constructor.unregister this unless @get 'meta.next'
    ).observes('meta.next')

    setData: (->
      @set 'data', Ember.ArrayProxy.create({content: []})
      @set 'meta', Ember.Object.create()
    ).on('init')

    loadRecords: ((href) ->
      @set 'isLoading', true
      Ember.$.getJSON(href || @get('href'), @ajaxCallback.bind(this))
    ).on('didInsertElement')

    loadNextRecords: ->
      @loadRecords @get('meta.next')

    ajaxCallback: (res, status, xhr) ->
      @get('data').pushObjects(@normalize(res, status, xhr))
      @set('meta', @extractMeta(res, status, xhr))
      @set 'isLoading', false

    normalize: (res) ->
      key = @get('data-key')
      if key then res[key] else res

    extractMeta: (res, status, xhr) ->
      parseLinkHeader xhr

  IcLazyList.reopenClass

    views: []

    register: (view) ->
      @views.addObject view
      if @views.length is 1
        $window.on 'scroll.ic-lazy-list', throttle(@checkViews.bind(this), 100)
      Ember.run.scheduleOnce 'afterRender', this, 'checkViews'

    unregister: (view) ->
      @views.removeObject(view)
      if @views.length is 0
        $window.off 'scroll.ic-lazy-list'

    checkViews: ->
      for view in @views
        continue if view.get('isLoading')
        {bottom} = view.get('element').getBoundingClientRect()
        if bottom <= window.innerHeight
          view.loadNextRecords()
      null

   register 'component', 'ic-lazy-list', IcLazyList

