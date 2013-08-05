require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
], ($, WikiPage, WikiPageView) ->

  $('body').addClass('pages show')

  wikiPage = new WikiPage ENV.wiki_page, contextAssetString: ENV.content_asset_string

  wikiPageView = new WikiPageView
    model: wikiPage
    wiki_pages_url: ENV.wiki_pages_url
    edit_wiki_path: ENV.EDIT_WIKI_PATH
  $('#content').append(wikiPageView.$el)

  wikiPageView.render()
