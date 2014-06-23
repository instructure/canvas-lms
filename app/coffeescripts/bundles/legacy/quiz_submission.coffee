require [
  "i18n!quizzes.quiz_submission",
  "jquery",
  "compiled/behaviors/quiz_selectmenu"
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


