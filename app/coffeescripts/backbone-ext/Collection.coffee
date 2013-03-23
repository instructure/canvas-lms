define [
  'use!vendor/backbone'
  'underscore'
  'compiled/str/splitAssetString'
], (Backbone, _, splitAssetString) ->

  class Backbone.Collection extends Backbone.Collection

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
    # `options` will be merged into @defaults. Some options will become direct
    # properties of your instance, see `_directPropertyOptions`
    initialize: (models, options) ->
      @options = _.extend {}, @defaults, options
      _.each @_directPropertyOptions, (prop) => @[prop] = @options[prop]
      super

    ##
    # Sets a paramter on @options.params that will be used in `fetch`
    setParam: (name, value) ->
      @options.params ?= {}
      @options.params[name] = value

    fetch: (options = {}) ->
      # TODO: we might want to merge options.data and options.params here instead
      options.data = @options.params if !options.data? and @options.params?
      super options

    url: -> @_defaultUrl()

    ##
    # Options with these keys become direct members of the instance.
    _directPropertyOptions: ['contextAssetString', 'resourceName']

    ##
    # In the spirit of convention over configuration, if the base API route of
    # your collection follows canvas's default routing pattern of:
    # /api/v1/<context_type>/<context_id>/<plural_form_of_resource_name> then
    # you can just define a `resourceName` property on your model or collection
    # and fall back on this default 'url' function.  This will look for a
    # @contextCode on your collection and fall back to
    # ENV.context_asset_string.
    #
    # So, for example say you are on /courses/1 and you do new
    # DiscussionTopicsCollection().fetch() it will go to
    # /api/v1/courses/1/discussion_topics (since ENV.context_asset_string will
    # be already set)
    _defaultUrl: ->
      assetString = @contextAssetString || ENV.context_asset_string
      resourceName = @resourceName || @model::resourceName
      throw new Error "Must define a `resourceName` property on collection or model prototype to use defaultUrl" unless resourceName
      [contextType, contextId] = splitAssetString assetString
      "/api/v1/#{contextType}/#{contextId}/#{resourceName}"

