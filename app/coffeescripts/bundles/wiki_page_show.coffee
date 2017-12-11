require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
  'compiled/util/markAsDone'
  'compiled/jquery/ModuleSequenceFooter'
], ($, WikiPage, WikiPageView, MarkAsDone) ->

  $ ->
    $('#content').on('click', '#mark-as-done-checkbox', ->
      MarkAsDone.toggle(this)
    )

  $('body').addClass('show')

  finalize_page_show = (wiki_page_modified) ->
    wikiPage = new WikiPage wiki_page_modified, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string

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
      display_show_all_pages: ENV.DISPLAY_SHOW_ALL_LINK

    wikiPageView.render()

  bzWikiPageContentPreload(ENV.WIKI_PAGE, finalize_page_show)
