require [
  "i18n!users.registered",
  "jquery",
  "jquery.ajaxJSON",
  "jqueryui/dialog"
], (I18n, $) ->
  $(document).ready ->
    runAjax = true
    $(".re_send_confirmation_link").click (event) ->
      event.preventDefault()

      #we dont really want them to just keep clicking resend a bunch of times,
      # if it doesnt work then its ok so they can try to see if they can get it to work.
      if runAjax
        $link = $(this)
        $link.text I18n.t("resending", "Re-Sending...")
        $.ajaxJSON $link.attr("href"), "POST", {}, ((data) ->
          $link.text I18n.t("done_resending", "Done! Message may take a few minutes.")
          runAjax = false
        ), (data) ->
          $link.text I18n.t("failed_resending", "Request failed. Try again.")

    videoWidth = Math.max(Math.min($(window).width() - 120, ($(window).height() * 1390 / 900 - 120)), 800)
    videoHeight = videoWidth * 900 / 1390
    params = allowScriptAccess: "always"
    atts = id: "youtube_player"
    swfobject.embedSWF "//www.youtube.com/v/SJY5p0qpzhA?version=3&rel=0&enablejsapi=1&disablekb=1&fs=1&hd=1&showsearch=0&iv_load_policy=3&feature=player_embedded", "youtube_player", videoWidth, videoHeight, "8", null, null, params, atts

    # $("#video").width(videoWidth).height(videoHeight);
    $("#play_overview_video_link").click ->
      $("#video_wrapper").dialog
        width: videoWidth
        title: I18n.t("overview_video", "Overview Video of Canvas")
      false

  onYouTubePlayerReady = (playerid) ->
    player = document.getElementById("youtube_player")
    player.setPlaybackQuality "hd720"
    player.playVideo()