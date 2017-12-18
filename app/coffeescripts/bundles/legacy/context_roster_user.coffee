#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  "jquery",
  "i18n!context.roster_user",
  "jsx/student_last_attended/index"
  "jquery.ajaxJSON",
  "jquery.instructure_misc_plugins",
  "jquery.loadingImg",
  "../../jquery.rails_flash_notifications",
  "link_enrollment"
], ($, I18n, initLastAttended) ->
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
        $enrollment.find(".conclude_enrollment_link_holder").show()
        $enrollment.find(".unconclude_enrollment_link_holder").hide()
        $enrollment.find(".completed_at_holder").hide()

    $(".conclude_enrollment_link").click (event) ->
      event.preventDefault()
      $(this).parents(".enrollment").confirmDelete
        message: I18n.t("confirm.conclude", "Are you sure you want to conclude this enrollment?")
        url: $(this).attr("href")
        success: (data) ->
          comp_at = $.datetimeString(data.enrollment.completed_at)
          $enrollment = $(this)
          $enrollment.undim()
          $enrollment.find(".conclude_enrollment_link_holder").hide()
          $enrollment.find(".unconclude_enrollment_link_holder").show()
          $enrollment.find(".completed_at_holder .completed_at").text(comp_at)
          $enrollment.find(".completed_at_holder").show()

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
        message: I18n.t("confirm.delete_enrollment", "Are you sure you want to delete this enrollment?")
        url: $(this).attr("href")
        success: (data) ->
          $(this).closest(".enrollment").hide()

    $(".more_user_information_link").click (event) ->
      event.preventDefault()
      $(".more_user_information").slideDown()
      $(this).hide()

    initLastAttended(document.getElementById("student_last_attended__component"), ENV.COURSE_ID, ENV.USER_ID, ENV.LAST_ATTENDED_DATE)
