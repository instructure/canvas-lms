define ['quiz_rubric', 'jquery'], (QuizRubric, $)->
  assignmentRubricHtml = "" +
    "<div id='test-rubrics-wrapper'>" +
      "<div id=\"rubrics\" class=\"rubric_dialog\">" +
        "<a href='#' class='btn add_rubric_link'>Add Rubric</a>" +
      "</div>" +
      "<script>" +
        "window.ENV = window.ENV || {};" +
        "window.ENV.ROOT_OUTCOME_GROUP = {};" +
        "var event = document.createEvent('Event');" +
        "event.initEvent('rubricEditDataReady', true, true);" +
        "document.dispatchEvent(event)" +
      "</script>" +
    "</div>"

  defaultRubric = "" +
    "<div id='default_rubric'>" +
      "DUMMY CONTENT FOR RUBRIC FORM" +
    "</div>"

  QUnit.module "QuizRubric",
    setup: ->
      $("#fixtures").append(defaultRubric)

    teardown: ->
      $("#test-rubrics-wrapper").remove()
      $("#fixtures").html("")

  test 'rubric editing event loads the rubric form', ->
    QuizRubric.createRubricDialog("#", assignmentRubricHtml)
    $(".add_rubric_link").click()
    contentIndex = $("#rubrics").html().indexOf("DUMMY CONTENT FOR RUBRIC FORM")
    ok(contentIndex > 0)
