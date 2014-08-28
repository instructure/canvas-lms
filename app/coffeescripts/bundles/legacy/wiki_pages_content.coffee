require [
  'jquery',
  'wiki',
  'vendor/jquery.pageless'
], ($, wikiPage) ->

  wikiPage.init()
  $(document).ready ->
    $("#wiki_show_view_secondary .edit_link:first").click() if ENV.WIKI_PAGE_EDITING

