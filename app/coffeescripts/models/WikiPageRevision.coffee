define [
  'underscore'
  'Backbone'
  'i18n!pages'
  'compiled/backbone-ext/DefaultUrlMixin'
  'compiled/str/splitAssetString'
], (_, Backbone, I18n, DefaultUrlMixin, splitAssetString) ->

  pageRevisionOptions = ['contextAssetString', 'page', 'pageUrl', 'latest', 'summary']

  class WikiPageRevision extends Backbone.Model
    @mixin DefaultUrlMixin

    initialize: (attributes, options) ->
      super
      _.extend(this, _.pick(options || {}, pageRevisionOptions))

      # the CollectionView managing the revisions "accidentally" passes in a url, so we have to nuke it here...
      delete @url if _.has(@, 'url')

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/pages/#{@pageUrl}/revisions"

    url: ->
      base = @urlRoot()
      return "#{base}/latest" if @latest
      return "#{base}/#{@get('revision_id')}" if @get('revision_id')
      return base

    fetch: (options={}) ->
      if @summary
        options.data ?= {}
        options.data.summary ?= true
      super options

    pollForChanges: (interval=30000) ->
      @polling = true
      unless @_poller
        poll = =>
          return unless @polling
          @fetch().done (data, status, xhr) ->
            status = xhr.status.toString()
            poll() unless status[0] == '4' || status[0] == '5'
        @_poller = poll = _.throttle poll, interval, leading: false

      @_poller()

    stopPolling: ->
      @polling = false

    parse: (response, options) ->
      response.id = response.url if response.url
      response

    toJSON: ->
      _.omit super, 'id'

    restore: ->
      d = $.ajaxJSON(@url(), 'POST').fail ->
        $.flashError I18n.t 'restore_failed', 'Failed to restore page revision'
      $('#wiki_page_revisions').disableWhileLoading($.Deferred())
      d
