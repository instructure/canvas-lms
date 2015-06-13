define [
  'jquery'
  'jst/assignments/ExternalContentHomeworkUrlSubmissionView'
  'compiled/views/assignments/ExternalContentHomeworkSubmissionView'
], ($, template, ExternalContentHomeworkSubmissionView) ->

  class ExternalContentUrlSubmissionView extends ExternalContentHomeworkSubmissionView
    template: template
    @optionProperty 'externalTool'

    submitHomework: =>
      data =
        submission:
          submission_type: "online_url"
          url: @model.get('url')
        comment:
          text_comment: @model.get('comment')

      submissionUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions"
      $.ajaxJSON submissionUrl, "POST", data, @redirectSuccessfulAssignment

    redirectSuccessfulAssignment: (responseData) =>
      window.onbeforeunload = -> # remove alert message from being triggered
      window.location.reload()

