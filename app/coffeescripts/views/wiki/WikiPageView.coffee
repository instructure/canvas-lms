define [
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jst/wiki/WikiPage'
], (_, Backbone, splitAssetString, template) ->

  class WikiPageView extends Backbone.View
    template: template

    events:
      'click button.publish': 'publishPage'
      'click button.unpublish': 'unpublishPage'

    @optionProperty 'wiki_pages_url'

    initialize: ->
      @model.on 'change', => @render()
      super

    publishPage: (ev) ->
      ev.preventDefault()
      @model?.publish()

    unpublishPage: (ev) ->
      ev.preventDefault()
      @model?.unpublish()

    toJSON: ->
      _.extend super, wiki_pages_url: @wiki_pages_url
