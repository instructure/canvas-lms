require [
  'jquery'
  'quiz_inputs'
  'quiz_show'
  'quiz_rubric'
  'message_students'
  'jquery.disableWhileLoading'
  'compiled/jquery/ModuleSequenceFooter'
], ($, inputMethods) ->
  $ ->
    inputMethods.setWidths()
    $('.answer input[type=text]').each ->
      $(this).width(($(this).val().length or 11) * 9.5)

    $(".download_submissions_link").click (event) ->
      event.preventDefault()
      INST.downloadSubmissions($(this).attr('href'))

    # load in regrade versions
    if ENV.SUBMISSION_VERSIONS_URL && !ENV.IS_SURVEY
      versions = $("#quiz-submission-version-table")
      versions.css(height: "100px")
      dfd = $.get ENV.SUBMISSION_VERSIONS_URL, (html) ->
        versions.html(html)
        versions.css(height: "auto")
      versions.disableWhileLoading(dfd)

    # Add module sequence footer
    $('#module_sequence_footer').moduleSequenceFooter(
      courseID: ENV.COURSE_ID
      assetType: 'Quiz'
      assetID: ENV.QUIZ.id
      location: location
    )
