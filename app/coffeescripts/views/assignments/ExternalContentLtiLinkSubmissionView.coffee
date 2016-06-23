define [
  'jquery'
  'jst/assignments/ExternalContentHomeworkUrlSubmissionView'
  'compiled/views/assignments/ExternalContentHomeworkSubmissionView'
], ($, template, ExternalContentHomeworkSubmissionView) ->

  class ExternalContentLtiLinkSubmissionView extends ExternalContentHomeworkSubmissionView
    template: template
    @optionProperty 'externalTool'

    buildSubmission: ->
      submission_type: 'basic_lti_launch'
      url: @model.get('url')

    extractComment: ->
      text_comment: @model.get('comment')

    submissionURL: ->
      "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions"

    submitHomework: =>
      data =
        submission: @buildSubmission()
        comment: @extractComment()
      $.ajaxJSON @submissionURL(), "POST", data, @redirectSuccessfulAssignment

    redirectSuccessfulAssignment: (responseData) =>
      window.onbeforeunload = -> # remove alert message from being triggered
      window.location.reload()

