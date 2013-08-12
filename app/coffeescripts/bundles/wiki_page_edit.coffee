require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageEditView'
], ($, WikiPage, WikiPageEditView) ->

  $('body').addClass('pages edit')

  wikiPage = new WikiPage ENV.wiki_page, contextAssetString: ENV.context_asset_string

  wikiPageEditView = new WikiPageEditView
    model: wikiPage
    wiki_pages_url: ENV.wiki_pages_url
  $('#content').append(wikiPageEditView.$el)

  wikiPageEditView.render()
