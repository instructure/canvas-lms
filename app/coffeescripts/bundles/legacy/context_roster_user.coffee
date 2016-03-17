require [
  "jquery",
  "i18n!context.roster_user",
  "jquery.ajaxJSON",
  "jquery.instructure_misc_plugins",
  "jquery.loadingImg",
  "compiled/jquery.rails_flash_notifications",
  "link_enrollment"
], ($, I18n) ->
  $(document).ready ->
    $(".show_user_services_checkbox").change ->
      $.ajaxJSON $(".profile_url").attr("href"), "PUT",
        "user[show_user_services]": $(this).prop("checked")
      , ((data) ->
        ), (data) ->

    $(".unconclude_enrollment_link").click (event) ->
      event.preventDefault()
      $enrollment = $(this).parents(".enrollment")
      $.ajaxJSON $(this).attr("href"), "POST", {}, (data) ->
        $enrollment.find(".conclude_enrollment_link_holder").slideDown()
        $enrollment.find(".unconclude_enrollment_link_holder").slideUp()
        $enrollment.find(".completed_at_holder").slideUp()


    $(".conclude_enrollment_link").click (event) ->
      event.preventDefault()
      $(this).parents(".enrollment").confirmDelete
        message: I18n.t("confirm.conclude_student", "Are you sure you want to conclude this student's enrollment?")
        url: $(this).attr("href")
        success: (data) ->
          $(this).undim()
          $(this).find(".conclude_enrollment_link_holder").slideUp()
          $(this).find(".unconclude_enrollment_link_holder").slideDown()

    $(".elevate_enrollment_link,.restrict_enrollment_link").click (event) ->
      limit = (if $(this).hasClass("restrict_enrollment_link") then "1" else "0")
      $user = $(this).parents(".tr")
      $user.loadingImage()
      $.ajaxJSON $(this).attr("href"), "POST",
        limit: limit
      , ((data) ->
          $user.loadingImage "remove"
          $(".elevate_enrollment_link_holder,.restrict_enrollment_link_holder").slideToggle()
        ), ((data) ->
          $.flashError I18n.t("enrollment_change_failed", "Enrollment privilege change failed, please try again")
          $user.loadingImage "remove"
        )
      event.preventDefault()

    $(".delete_enrollment_link").click (event) ->
      event.preventDefault()
      $(this).parents(".enrollment").confirmDelete
        message: I18n.t("confirm.delete_enrollment", "Are you sure you want to delete this student's enrollment?")
        url: $(this).attr("href")
        success: (data) ->
          $(this).closest(".enrollment").hide()

    $(".more_user_information_link").click (event) ->
      event.preventDefault()
      $(".more_user_information").slideDown()
      $(this).hide()


