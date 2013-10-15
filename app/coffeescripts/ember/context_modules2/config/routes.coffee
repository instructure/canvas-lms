define [
], () ->

  # App.ModuleAddRoute = Ember.Route.extend
  #   renderTemplate: ->
  #     @render 'add',
  #       into: 'index'
  #       outlet: 'modal'
  #   model: (params) ->
  #     console.log 'params', params
  #     []

  # App.ModuleAddRoute = Ember.Route.extend
  #   renderTemplate: ->
  #     @render 'add',
  #       into: 'index'
  #       outlet: 'modal'
  #   model: (params) ->
  #     console.log 'params', params
  #     []

  # App.ModuleSearchRoute = Ember.Route.extend
  #   model: (params) ->
  #     console.log 'params', params
  #     []

  routes = ->
    @resource 'modules', path: '/' , ->
      @route 'add'
      @resource 'module_items',
        path: '/:module_id/items'
      , ->
      	@route 'add',
          path: '/add'
      @route 'search',
        path: 'search/:query'
    @route 'missing', path: '*:'