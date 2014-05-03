require ['jquery', 'full_files', 'jquery.google-analytics', 'uploadify'], ($) ->

  $ ->
    $('.manage_collaborations').on 'click', ->
      $.trackEvent('files', 'click', 'manage_collaborations')

