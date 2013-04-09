define ['jquery', 'jquery.google-analytics'], ($) ->

  ##
  # Track click events to google analytics with HTML
  #
  #   <a
  #     data-track-category="some category"
  #     data-track-label="some label"
  #     data-track-action="some action"
  #     data-track-value="some value"
  #   >click here</a>
  $('body').on 'click', '[data-track-category]', (event) ->
    {trackCategory, trackLabel, trackAction, trackValue} = $(this).data()
    $.trackEvent(trackCategory, trackAction, trackLabel, trackValue)
    null

