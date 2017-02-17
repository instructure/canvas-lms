define [
  'node_modules-version-of-backbone'
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
        @[property] = @options[property] if @options[property] isnt undefined

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
      super(options).then(null, (xhr) => @trigger 'fetch:fail', xhr)

    url: -> @_defaultUrl()

    @optionProperty 'contextAssetString'

    @optionProperty 'resourceName'

    ##
    # Overridden to allow recognition of jsonapi.org url style compound
    # documents.
    #
    # These compound documents side load related objects as secondary
    # collections under the linked attribute, rather than embedded within
    # the primary collection's objects. The primary collection is defined
    # by following the jsonapi.org standard.  This will look for the first
    # collection after removing reserved keys.
    #
    # To adapt this style to Backbone, we check for any jsonapi.org reserved
    # keys and, if any are found, we extract the first primary collection and
    # pre-process any declared side loads into the embedded format that Backbone
    # expects.
    #
    # Declaring recognized side loads is done through the `sideLoad' property
    # on the collection class. The value of this property is an object whose
    # keys identify the target relation property on the primary objects. The
    # values for those keys can either be `true', a string, or an object.
    #
    # If the value is an object, the foreign key and side loaded collection
    # name are identified by the `foreignKey' and `collection' properties,
    # respectively. Absent properties are inferred from the relation name.
    #
    # A value is `true' is treated the same as an empty object (side load
    # defined, but properties to be inferred). A string value is treated as a
    # hash with a collection name, leaving the foreign key to be inferred.
    #
    # If the value of a foreign key is an array it will be treated as a to_many
    # relationship and load all related documents.
    #
    # For examples, the following are all identical:
    #
    #   sideLoad:
    #     author: true
    #
    #   sideLoad:
    #     author:
    #       collection: 'authors'
    #
    #   sideLoad:
    #     author:
    #       foreignKey: 'author'
    #       collection: 'authors'
    #
    # If the authors are instead contained in the `people' collection, the
    # following can be used interchangeably:
    #
    #   sideLoad:
    #     author:
    #       collection: 'people'
    #
    #   sideLoad:
    #     author:
    #       foreignKey: 'author'
    #       collection: 'people'
    #
    # Alternately, if the collection is `authors' and the target relation
    # property is `author', but the foreign key is `person' (such a silly
    # API), you can use:
    #
    #   sideLoad:
    #     author:
    #       foreignKey: 'person'
    #
    parse: (response, options) ->
      return super unless response?
      rootMeta = _.pick(response, 'meta', 'links', 'linked')
      return super if _.isEmpty(rootMeta)

      collections = _.omit(response, 'meta', 'links', 'linked')
      return super if _.isEmpty(collections)
      collectionKeys = _.keys(collections)

      primaryCollectionKey = _.first(collectionKeys)
      primaryCollection = collections[primaryCollectionKey]
      return super unless primaryCollection?

      if collectionKeys.length > 1
        console?.warn?("Found more then one primary collection, using '#{primaryCollectionKey}'.")

      index = {}
      _.each rootMeta.linked || {}, (link, key) ->
        index[key] = _.indexBy(link, 'id')
      return super primaryCollection, options if _.isEmpty(index)

      _.each (@sideLoad || {}), (meta, relation) ->
        meta = {} if _.isBoolean(meta) && meta
        meta = {collection: meta} if _.isString(meta)
        return unless _.isObject(meta)

        {foreignKey, collection} = meta
        foreignKey ?= "#{relation}"
        collection ?= "#{relation}s"
        collection = index[collection] || {}

        _.each primaryCollection, (item) ->
          return unless item.links
          related = null

          id = item.links[foreignKey]
          if _.isArray(id)
            if _.isEmpty(collection)
              collection = index[relation] || index[foreignKey]
              unless collection?
                throw "Could not find linked collection for '#{relation}' using '#{foreignKey}'."
            related = _.map id, (pk) ->
              collection[pk]
          else
            related = collection[id]

          if id? && related?
            item[relation] = related
            delete item.links[foreignKey]
            delete item.links if _.isEmpty(item.links)

      super primaryCollection, options
