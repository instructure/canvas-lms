require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
  'compiled/util/markAsDone'
  'compiled/jquery/ModuleSequenceFooter'
], ($, WikiPage, WikiPageView, MarkAsDone) ->

  $ ->
    $('#mark-as-done-checkbox').click ->
      MarkAsDone.toggle(this)

  $('body').addClass('show')

  wikiPage = new WikiPage ENV.WIKI_PAGE, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string

  wikiPageView = new WikiPageView
    el: '#wiki_page_show'
    model: wikiPage
    modules_path: ENV.MODULES_PATH
    wiki_pages_path: ENV.WIKI_PAGES_PATH
    wiki_page_edit_path: ENV.WIKI_PAGE_EDIT_PATH
    wiki_page_history_path: ENV.WIKI_PAGE_HISTORY_PATH
    WIKI_RIGHTS: ENV.WIKI_RIGHTS
    PAGE_RIGHTS: ENV.PAGE_RIGHTS
    course_id: ENV.COURSE_ID
    course_home: ENV.COURSE_HOME
    course_title: ENV.COURSE_TITLE

  wikiPageView.render()
