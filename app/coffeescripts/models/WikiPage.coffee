define [
  'underscore'
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
  'compiled/str/splitAssetString'
], (_, Backbone, DefaultUrlMixin, splitAssetString) ->

  class WikiPage extends Backbone.Model
    resourceName: 'pages'

    @mixin DefaultUrlMixin
    url: -> "#{@_defaultUrl()}" + if @get('url') then "/#{@get('url')}" else ''

    initialize: (attributes, options) ->
      super
      @contextAssetString = options?.contextAssetString
      [@contextName, @contextId] = splitAssetString(@contextAssetString) if @contextAssetString
      @set('id', @get('url')) if @get('url') && !@get('id')

    # Flatten the nested data structure required by the api (see @publish and @unpublish)
    parse: (response, options) ->
      if response.wiki_page
        response = _.extend _.omit(response, 'wiki_page'), response.wiki_page

      response.id = response.url if response.url
      response

    # Gives a json representation of the model
    #
    # Specifically, the id is removed as the only reason for it's presense is to make Backbone happy
    toJSON: ->
      _.omit super, 'id'

    # Returns a json representation suitable for presenting
    present: ->
      _.extend _.omit(@toJSON(), 'id'), contextName: @contextName, contextId: @contextId, new_record: !@get('url')

    # Uses the api to perform a publish on the page
    publish: ->
      attributes =
        wiki_page:
          published: true
      @save attributes, wait: true

    # Uses the api to perform an unpublish on the page
    unpublish: ->
      attributes =
        wiki_page:
          published: false
      @save attributes, wait: true

    # Uses the api to set the page as the front page
    setAsFrontPage: ->
      attributes =
        wiki_page:
          front_page: true
      @save attributes, wait: true

    # Uses the api to remove the page as the front page
    removeAsFrontPage: ->
      attributes =
        wiki_page:
          front_page: false
      @save attributes, wait: true
