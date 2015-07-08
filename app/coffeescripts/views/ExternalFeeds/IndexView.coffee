define [
  'underscore'
  'compiled/views/ValidatedFormView'
  'compiled/models/ExternalFeed'
  'jst/ExternalFeeds/IndexView'
  'compiled/fn/preventDefault'
  'jquery'
  'jquery.toJSON'
], (_, ValidatedFormView, ExternalFeed, template, preventDefault, $) ->

  class IndexView extends ValidatedFormView

    template: template

    el: '#right-side'

    events:
      'submit #add_external_feed_form' : 'submit'
      'click [data-delete-feed-id]' : 'deleteFeed'

    initialize: ->
      super
      @createPendingModel()
      @collection.on 'all', @render, this
      @render()

    createPendingModel: ->
      @model = new ExternalFeed

    toJSON: ->
      json = @collection.toJSON()
      json.cid = @cid
      json.ENV = window.ENV if window.ENV?
      json

    render: ->
      if @collection.length || @options.permissions.create
        $('body').addClass('with-right-side')
        super

    deleteFeed: preventDefault (event) ->
      id = @$(event.target).data('deleteFeedId')
      @collection.get(id).destroy()

    getFormData: ->
      @$('#add_external_feed_form').toJSON()

    onSaveSuccess: =>
      super
      @collection.add(@model)
      @createPendingModel()
