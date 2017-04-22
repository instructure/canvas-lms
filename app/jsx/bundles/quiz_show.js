import $ from 'jquery'
import inputMethods from 'quiz_inputs'
import 'quiz_show'
import 'quiz_rubric'
import 'message_students'
import 'jquery.disableWhileLoading'
import 'compiled/jquery/ModuleSequenceFooter'

$(() => {
  inputMethods.setWidths()
  $('.answer input[type=text]').each(function () {
    $(this).width(($(this).val().length || 11) * 9.5)
  })

  $('.download_submissions_link').click(function (event) {
    event.preventDefault()
    INST.downloadSubmissions($(this).attr('href'))
  })

    // load in regrade versions
  if (ENV.SUBMISSION_VERSIONS_URL && !ENV.IS_SURVEY) {
    const versions = $('#quiz-submission-version-table')
    versions.css({height: '100px'})
    const dfd = $.get(ENV.SUBMISSION_VERSIONS_URL, (html) => {
      versions.html(html)
      versions.css({height: 'auto'})
    })
    versions.disableWhileLoading(dfd)
  }

    // Add module sequence footer
  $('#module_sequence_footer').moduleSequenceFooter({
    courseID: ENV.COURSE_ID,
    assetType: 'Quiz',
    assetID: ENV.QUIZ.id,
    location
  })
})
