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
  "i18n!quizzes.quiz_submission",
  "jquery",
  "../../behaviors/quiz_selectmenu"
], (I18n, $) ->
  $(document).ready ->
    $("#questions.assessment_results .question").hover (->
      $(this).addClass "hover"
    ), ->
      $(this).removeClass "hover"

    $(".quiz_response_text img").each ->
      $(this).css(
        borderColor: "#f44"
        borderStyle: "solid"
        borderWidth: "2px"
        padding: 2
      ).attr "title", I18n.t("titles.this_is_an_image", "This is an image, not text, and could have changed since the student submitted")

    $(".quiz_response_text iframe").each ->
      $(this).css(
        borderColor: "#f44"
        borderStyle: "solid"
        borderWidth: "2px"
        padding: 2
      ).attr "title", I18n.t("titles.this_is_an_external_frame", "This is an external frame, not text, and could have changed since the student submitted")

    $list = $("nothing")
    $(".quiz_response_text").find("object,embed").each ->
      $list.add $(this).parents("object,embed:first")

    $list.each ->
      $holder = $("<span/>").css("display", "inline-block")
      $holder.before $(this)
      $holder.append $(this)
      $holder.css(
        borderColor: "#f44"
        borderStyle: "solid"
        borderWidth: "2px"
        padding: 2
      ).attr "title", I18n.t("titles.this_is_an_external_element", "This is an external element, not text, and could have changed since the student submitted")


