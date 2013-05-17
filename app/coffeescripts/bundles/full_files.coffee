require ['full_files', 'jquery.google-analytics', 'use!uploadify'], ->

  $ ->
    $('.manage_collaborations').on 'click', ->
      $.trackEvent('files', 'click', 'manage_collaborations')

