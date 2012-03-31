define ['use!backbone', 'use!underscore'], (Backbone, _) ->

  _.extend Backbone.View.prototype,

    render: (opts = {}) ->
      @_filter() unless opts.noFilter is true

    _filter: ->
      @$('[data-bind]').each => @_createBinding.apply this, arguments
      @$('[data-behavior]').each => @_createBehavior.apply this, arguments

    _createBinding: (index, el) ->
      $el = $ el
      attribute = $el.data 'bind'
      @model.bind "change:#{attribute}", (model, value) =>
        $el.html value

    _createBehavior: (index, el) ->

  Backbone.View

