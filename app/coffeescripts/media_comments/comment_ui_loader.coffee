define [
  'jquery',
  'i18n!media_comments'
], ($, I18n) ->

  ###
  # Loads html partial for display within the uploader
  ###
  class CommentUiLoader

    loadTabs: (readyFunction) ->
      $.get "/partials/_media_comments.html", (html) ->
        readyFunction(html)
        $("#media_comment_dialog")
