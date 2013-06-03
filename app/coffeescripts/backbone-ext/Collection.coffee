define [
  'use!vendor/backbone'
  'underscore'
  'compiled/util/mixin'
  'compiled/backbone-ext/DefaultUrlMixin'
], (Backbone, _, mixin, DefaultUrlMixin) ->

  class Backbone.Collection extends Backbone.Collection
    ##
    # Mixes in objects to a model's definition, being mindful of certain
    # properties (like defaults) that need to be merged also.
    #
    # @param {Object} mixins...
    # @api public

    @mixin: (mixins...) ->
      mixin this, mixins...

    @mixin DefaultUrlMixin

    ##
    # Define default options, options passed in to the constructor will
    # overwrite these
    defaults:

      ##
      # Define some parameters for fetching, they'll be added to the url
      #
      # For example:
      #
      #   params:
      #     foo: 'bar'
      #     baz: [1,2]
      #
      # becomes:
      #
      #   ?foo=bar&baz[]=1&baz[]=2
      params: undefined

      ##
      # If using the conventional default URL, define a resource name here or
      # on your model. See `_defaultUrl` for more details.
      resourceName: undefined

      ##
      # If using the conventional default URL, define this, or let it fall back
      # to ENV.context_asset_url. See `_defaultUrl` for more details.
      contextAssetString: undefined

    ##
    # Defines a key on the options object to be added as an instance property
    # like `model`, `collection`, `el`, etc. on a Backbone.View
    #
    # Example:
    #   class UserCollection extends Backbone.Collection
    #     @optionProperty 'sections'
    #   view = new UserCollection
    #     sections: new SectionCollection
    #   view.sections #=> SectionCollection
    #
    #  @param {String} property
    #  @api public

    @optionProperty: (property) ->
      @__optionProperties__ = (@__optionProperties__ or []).concat [property]

    ##
    # Sets the option properties
    #
    # @api private

    setOptionProperties: ->
      for property in @constructor.__optionProperties__
        @[property] = @options[property] if @options[property]?

    ##
    # `options` will be merged into @defaults. Some options will become direct
    # properties of your instance, see `_directPropertyOptions`
    initialize: (models, options) ->
      @options = _.extend {}, @defaults, options
      @setOptionProperties()
      super

    ##
    # Sets a paramter on @options.params that will be used in `fetch`
    setParam: (name, value) ->
      @options.params ?= {}
      @options.params[name] = value
      @trigger 'setParam', name, value

    ##
    # Sets multiple params at once and triggers setParams event
    #
    # @param {Object} params
    setParams: (params) ->
      @setParam name, value for name, value of params
      @trigger 'setParams', params

    ##
    # Deletes a parameter from @options.params
    deleteParam: (name) ->
      delete @options.params?[name]
      @trigger 'deleteParam', name

    fetch: (options = {}) ->
      # TODO: we might want to merge options.data and options.params here instead
      options.data = @options.params if !options.data? and @options.params?
      super(options).fail (xhr) => @trigger 'fetch:fail', xhr

    url: -> @_defaultUrl()

    @optionProperty 'contextAssetString'

    @optionProperty 'resourceName'

