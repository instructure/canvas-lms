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
  "i18n!assignments.peer_reviews",
  "jquery",
  "jquery.ajaxJSON",
  "jquery.instructure_date_and_time", # $.datetimeString
  "jquery.instructure_forms",
  "jquery.instructure_misc_helpers",
  "jquery.instructure_misc_plugins",
  "jquery.loadingImg",
  "jquery.templateData"
], (I18n, $) ->
  $(document).ready ->
    $(".peer_review").hover (->
      $(".peer_review.submission-hover").removeClass "submission-hover"
      $(this).addClass "submission-hover"
    ), ->
      $(this).removeClass "submission-hover"

    $(".peer_review").focusin (->
      $(this).addClass "focusWithin"
    )
    $(".peer_review").focusout (event) ->
      $parent = $(this).closest(".peer_review")
      $newFocus = $(event.related).closest(".peer_review")
      unless ($newFocus.is($parent))
        $parent.removeClass "focusWithin"

    $(".peer_review .delete_review_link").click (event) ->
      event.preventDefault()
      next = $(this).parents(".peer_review").next().find("a").add(
        $(this).parents(".student_reviews").find(".assign_peer_review_link")
      ).first()
      $(this).parents(".peer_review").confirmDelete
        url: $(this).attr("href")
        message: I18n.t("messages.cancel_peer_review", "Cancel this peer review?")
        success: ->
          $(this).fadeOut 'slow', () ->
            $parent = $(this).parents(".peer_reviews")
            $(this).remove()
            if $parent.find(".assigned").length is 0
              $parent.find(".no_requests_message").show()
            next.focus()

    $(".assign_peer_review_link").click (event) ->
      event.preventDefault()
      #if the form is there and is being shown, then slide it up.
      if $(this).parents(".student_reviews").find(".form_content form:visible").length
        $(this).parents(".student_reviews").find(".form_content form:visible").slideUp()
      else #otherwise make it and inject it then slide it down
        $form = $("#assign_peer_review_form").clone(true).removeAttr("id")
        url = $(".assign_peer_review_url").attr("href")
        user_id = $(this).parents(".student_reviews").getTemplateData(textValues: ["student_review_id"]).student_review_id
        url = $.replaceTags(url, "reviewer_id", user_id)
        $form.find("select option.student_" + user_id).attr "disabled", true
        $(this).parents(".student_reviews").find(".peer_review").each ->
          user_id = $(this).getTemplateData(textValues: ["user_id"]).user_id
          $form.find("select option.student_" + user_id).attr "disabled", true
        $form.attr "action", url
        $(this).parents(".student_reviews").find(".form_content").empty().append $form
        $form.slideDown()

    $("#assign_peer_review_form").formSubmit
      beforeSubmit: (data) ->
        return false  unless data.reviewee_id
        $(this).loadingImage()
      success: (data) ->
        $(this).loadingImage "remove"
        $(this).slideUp ->
          $(this).remove()
        $review = $("#review_request_blank").clone(true).removeAttr("id")
        $review.fillTemplateData
          data: data.assessment_request
          hrefValues: ["id", "user_id"]
        $(this).parents(".student_reviews").find(".no_requests_message").slideUp().end().find(".peer_reviews").append $review
        $review.slideDown()
        $review.find("a").first().focus()
        assessor_name = $(this).parents(".student_reviews").find(".assessor_name").text()
        time = $.datetimeString(data.assessment_request.updated_at)
        $review.find(".reminder_peer_review_link").attr "title", I18n.t("titles.reminder", "Remind %{assessor} about Assessment, last notified %{time}", { assessor: assessor_name, time: time })
        $(this).slideUp ->
          $(this).remove()
      error: (data) ->
        $(this).loadingImage "remove"
        $(this).formErrors data

    $(".remind_peer_review_link").click (event) ->
      event.preventDefault()
      $link = $(this)
      $link.parents(".peer_review").loadingImage image_size: "small"
      $.ajaxJSON $link.attr("href"), "POST", {}, (data) ->
        $link.parents(".peer_review").loadingImage "remove"
        assessor_name = $link.parents(".student_reviews").find(".assessor_name").text()
        time = $.datetimeString(data.assessment_request.updated_at)
        $link.attr "title", I18n.t("titles.remind", "Remind %{assessor} about Assessment, last notified %{time}", { assessor: assessor_name, time: time })

    $(".remind_peer_reviews_link").click (event) ->
      event.preventDefault()
      $(".peer_review.assigned .remind_peer_review_link").click()
