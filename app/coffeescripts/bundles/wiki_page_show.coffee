require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
  'compiled/jquery/ModuleSequenceFooter'
], ($, WikiPage, WikiPageView) ->

  $('body').addClass('pages show')

  wikiPage = new WikiPage ENV.WIKI_PAGE, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string

  wikiPageView = new WikiPageView
    model: wikiPage
    wiki_pages_path: ENV.WIKI_PAGES_PATH
    wiki_page_edit_path: ENV.WIKI_PAGE_EDIT_PATH
    wiki_page_history_path: ENV.WIKI_PAGE_HISTORY_PATH
    WIKI_RIGHTS: ENV.WIKI_RIGHTS
    PAGE_RIGHTS: ENV.PAGE_RIGHTS
  $('#content').append(wikiPageView.$el)

  wikiPageView.render()

  # Add module sequence footer if the context is a course
  if ENV.COURSE_ID
    $('#module_sequence_footer').moduleSequenceFooter(
      courseID: ENV.COURSE_ID
      assetType: 'Page'
      assetID: ENV.WIKI_PAGE.url
      location: location
    )
