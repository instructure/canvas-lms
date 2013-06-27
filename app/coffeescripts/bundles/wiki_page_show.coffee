require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
], ($, WikiPage, WikiPageView) ->

  $('body').addClass('pages show')

  wiki_page = new WikiPage ENV.wiki_page, contextAssetString: ENV.content_asset_string

  wiki_page_view = new WikiPageView
    model: wiki_page
    wiki_pages_url: ENV.wiki_pages_url

  wiki_page_view.render()
  $('#content').append(wiki_page_view.$el)
