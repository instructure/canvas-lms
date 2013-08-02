define [
  'Backbone'
  'underscore'
  'jst/ExternalFeeds/IndexView'
  'compiled/fn/preventDefault'
  'jquery'
  'jquery.toJSON'
], (Backbone, _, template, preventDefault, $) ->

  class IndexView extends Backbone.View

    template: template

    el: '#right-side'

    events:
      'submit #add_external_feed_form' : 'submit'
      'click [data-delete-feed-id]' : 'deleteFeed'

    initialize: ->
      super
      @collection.on 'all', @render, this
      @render()

    render: ->
      if @collection.length || @options.permissions.create
        $('body').addClass('with-right-side')
        super

    deleteFeed: preventDefault (event) ->
      id = @$(event.target).data('deleteFeedId')
      @collection.get(id).destroy()

    submit: preventDefault (event) ->
      data = @$('#add_external_feed_form').toJSON()
      @$el.disableWhileLoading @collection.create data, wait: true