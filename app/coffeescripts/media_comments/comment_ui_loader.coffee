define [
  'jquery',
  'i18n!media_comments'
  'jst/MediaComments'
], ($, I18n, mediaCommentsTemplate) ->

  ###
  # Loads html partial for display within the uploader
  ###
  class CommentUiLoader

    loadTabs: (readyFunction) ->
      readyFunction(mediaCommentsTemplate())
      $("#media_comment_dialog")
