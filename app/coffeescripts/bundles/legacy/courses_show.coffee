require [
  "jquery",
  "i18n!courses.show",
  "str/htmlEscape",
  "jquery.ajaxJSON",
  "jqueryui/dialog",
  "compiled/jquery/fixDialogButtons",
  "jquery.loadingImg",
  "vendor/jquery.scrollTo",
  "compiled/behaviors/openAsDialog"
], ($, I18n, htmlEscape) ->
  $(document).ready ->
    $selfUnenrollmentDialog = $("#self_unenrollment_dialog")
    $(".self_unenrollment_link").click (event) ->
      $selfUnenrollmentDialog.dialog(title: I18n.t("titles.drop_course", "Drop this Course")).fixDialogButtons()

    $selfUnenrollmentDialog.on "click", ".action", ->
      $selfUnenrollmentDialog.disableWhileLoading $.Deferred()
      $.ajaxJSON $(this).attr("href"), "POST", {}, ->
        window.location.reload()

    $(".re_send_confirmation_link").click (event) ->
      event.preventDefault()
      $link = $(this)
      $link.text I18n.t("re_sending", "Re-Sending...")
      $.ajaxJSON $link.attr("href"), "POST", {}, ((data) ->
        $link.text I18n.t("send_done", "Done! Message may take a few minutes.")
      ), (data) ->
        $link.text I18n.t("send_failed", "Request failed. Try again.")

    $(".home_page_link").click (event) ->
      event.preventDefault()
      $link = $(this)
      $(".floating_links").hide()
      $("#course_messages").slideUp ->
        $(".floating_links").show()

      $("#home_page").slideDown().loadingImage()
      $link.hide()
      $.ajaxJSON $(this).attr("href"), "GET", {}, (data) ->
        $("#home_page").loadingImage "remove"
        bodyHtml = htmlEscape($.trim(data.wiki_page.body))
        bodyHtml = htmlEscape(I18n.t("empty_body", "No Content")) if bodyHtml.length is 0
        $("#home_page_content").html bodyHtml
        $("html,body").scrollTo $("#home_page")

    $(".dashboard_view_link").click (event) ->
      event.preventDefault()
      $(".floating_links").hide()
      $("#course_messages").slideDown ->
        $(".floating_links").show()

      $("#home_page").slideUp()
      $(".home_page_link").show()

    $(".publish_course_in_wizard_link").click (event) ->
      event.preventDefault()
      if $("#wizard_box:visible").length > 0
        $("#wizard_box .option.publish_step").click()
      else
        $("#wizard_box").slideDown "slow", ->
          $(this).find(".option.publish_step").click()



