define ['underscore', 'jquery'], (_, $) ->

  class Sticky

    @instances: []

    @initialized: false

    @$container = $ window

    @initialize: ->
      @$container.on 'scroll', _.debounce(@checkInstances, 10)
      @initialized = true

    @addInstance: (instance) ->
      @initialize() unless @initialized
      @instances.push instance
      @checkInstances()

    @removeInstance: (instance) ->
      @initialize() unless @initialized
      @instances = _.reject @instances, (i) -> i == instance
      @checkInstances()

    @checkInstances: =>
      containerTop = @$container.scrollTop()
      for instance in @instances
        if containerTop >= instance.top
          instance.stick() unless instance.stuck
        else
          instance.unstick() if instance.stuck
      null

    constructor: (@$el) ->
      @top = @$el.offset().top
      @stuck = false
      @constructor.addInstance this

    stick: ->
      @$el.addClass 'sticky'
      @stuck = true

    unstick: ->
      @$el.removeClass 'sticky'
      @stuck = false

    remove: ->
      @unstick()
      @constructor.removeInstance this

  $.fn.sticky = ->
    @each -> new Sticky $ this

  $ -> $('[data-sticky]').sticky()

  Sticky
