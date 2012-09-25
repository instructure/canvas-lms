define ['jquery'], ($) ->
  $(document).ready ->
    if ENV.badge_counts
      for type, unread of ENV.badge_counts
        if unread > 0
          type = "discussions" if type is "discussion_topics"
          $badge = $("<b/>").append(unread).addClass("nav-badge")
          $("#section-tabs .#{type}").append($badge)
