define [
  'underscore'
  'Backbone'
  'compiled/models/WikiPageRevision'
  'compiled/backbone-ext/DefaultUrlMixin'
  'compiled/str/splitAssetString'
  'i18n!pages'
], (_, Backbone, WikiPageRevision, DefaultUrlMixin, splitAssetString, I18n) ->

  pageOptions = ['contextAssetString', 'revision']

  class WikiPage extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'pages'
    idAttribute: 'url'

    initialize: (attributes, options) ->
      super
      _.extend(this, _.pick(options || {}, pageOptions))
      [@contextName, @contextId] = splitAssetString(@contextAssetString) if @contextAssetString

      @on 'change:front_page', @setPublishable
      @on 'change:published', @setPublishable
      @setPublishable()

    setPublishable: ->
      front_page = @get('front_page')
      published = @get('published')
      publishable = !front_page || !published
      deletable = !front_page
      @set('publishable', publishable)
      @set('deletable', deletable)
      if publishable
        @unset('publishableMessage')
      else
        @set('publishableMessage', I18n.t('cannot_unpublish_front_page', 'Cannot unpublish the front page'))

    disabledMessage: ->
      @get('publishableMessage')

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/pages"

    url: ->
      if @get('url') then "#{@urlRoot()}/#{@get('url')}" else @urlRoot()

    latestRevision: (options) ->
      if !@_latestRevision && @get('url')
        unless @_latestRevision
          revisionOptions = _.extend({}, {@contextAssetString, page: @, pageUrl: @get('url'), latest: true, summary: true}, options)
          @_latestRevision = new WikiPageRevision({revision_id: @revision}, revisionOptions)
      @_latestRevision

    # Flatten the nested data structure required by the api (see @publish and @unpublish)
    parse: (response, options) ->
      if response.wiki_page
        response = _.extend _.omit(response, 'wiki_page'), response.wiki_page
      response

    # Gives a json representation of the model
    toJSON: ->
      wiki_page:
        super

    # Returns a json representation suitable for presenting
    present: ->
      _.extend {}, @attributes, contextName: @contextName, contextId: @contextId, new_record: !@get('url')

    # Uses the api to perform a publish on the page
    publish: ->
      attrs =
        wiki_page:
          published: true
      @save attrs, attrs: attrs, wait: true

    # Uses the api to perform an unpublish on the page
    unpublish: ->
      attrs =
        wiki_page:
          published: false
      @save attrs, attrs: attrs, wait: true

    # Uses the api to set the page as the front page
    setFrontPage: ->
      attrs =
        wiki_page:
          front_page: true
      @save attrs, attrs: attrs, wait: true

    # Uses the api to unset the page as the front page
    unsetFrontPage: ->
      attrs =
        wiki_page:
          front_page: false
      @save attrs, attrs: attrs, wait: true
