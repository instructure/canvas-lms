define [
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jst/wiki/WikiPage'
  'compiled/views/StickyHeaderMixin'
], (_, Backbone, splitAssetString, template, StickyHeaderMixin ) ->

  class WikiPageView extends Backbone.View

    @mixin StickyHeaderMixin

    template: template

    els:
      'button.publish, button.unpublish': '$publishButton'

    events:
      'click button.publish': 'publishPage'
      'click button.unpublish': 'unpublishPage'

    @optionProperty 'wiki_pages_url'
    @optionProperty 'edit_wiki_path'

    initialize: ->
      @model.on 'change', => @render()
      super

    publishPage: (ev) ->
      ev.preventDefault()
      @$publishButton.disableWhileLoading @model?.publish()

    unpublishPage: (ev) ->
      ev.preventDefault()
      @$publishButton.disableWhileLoading @model?.unpublish()

    toJSON: ->
      _.extend super, wiki_pages_url: @wiki_pages_url, edit_wiki_path: @edit_wiki_path
