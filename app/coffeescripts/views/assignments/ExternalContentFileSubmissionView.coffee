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
  'jquery'
  'i18n!assignments'
  'jst/assignments/ExternalContentHomeworkFileSubmissionView'
  './ExternalContentHomeworkSubmissionView'
], ($, I18n, template, ExternalContentHomeworkSubmissionView) ->

  class ExternalContentFileSubmissionView extends ExternalContentHomeworkSubmissionView
    template: template
    @optionProperty 'externalTool'

    submitHomework: =>
      @uploadFileFromUrl(@externalTool, @model)

    checkFileStatus: (url, callback, error) =>
      $.ajaxJSON url, "GET", {}, ((data) =>
        if data.upload_status is "ready"
          callback data.attachment
        else if data.upload_status is "errored"
          error data.message
        else
          setTimeout (=>
            @checkFileStatus url, callback, error
            return
          ), 2500
        return
      ), (data) ->
        error data.message

    submitAssignment: (fileData) =>
      data =
        submission:
          submission_type: "online_upload"
          file_ids: [ fileData.id ]
        comment:
          text_comment: @assignmentSubmission.get('comment')

      submissionUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions"
      $.ajaxJSON submissionUrl, "POST", data, @redirectSuccessfulAssignment, @disableLoader

      return

    redirectSuccessfulAssignment: (responseData) =>
      $(window).off('beforeunload') # remove alert message from being triggered
      window.location.reload()
      @loaderPromise.resolve()
      return

    disableLoader: =>
      @loaderPromise.resolve()

    submissionFailure: (message) =>
      @loaderPromise.resolve()
      @$el.find(".submit_button").text I18n.t("file_retrieval_error", "Retrieving File Failed")
      $.flashError I18n.t("invalid_file_retrieval", "There was a problem retrieving the file sent from this tool.")

    uploadSuccess: (data) =>
      @checkFileStatus data.status_url, @submitAssignment, @submissionFailure
      return

    uploadFailure: (data) =>
      @loaderPromise.resolve()
      @$el.find(".submit_button").text I18n.t("file_retrieval_error", "Retrieving File Failed")
      return

    uploadFileFromUrl: (tool, modelData) ->
      @loaderPromise = $.Deferred()

      @assignmentSubmission = modelData
      # build the params for submitting the assignment
      fileParams =
        url: @assignmentSubmission.get('url')
        name: @assignmentSubmission.get('text')
        content_type: ''

      if ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER?
        fileUploadUrl = "/api/v1/groups/" + ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER + "/files"
      else
        fileUploadUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions/" + ENV.current_user_id + "/files"

      $.ajaxJSON fileUploadUrl, "POST", fileParams, @uploadSuccess, @uploadFailure

      @$el.disableWhileLoading @loaderPromise,
        buttons:
          ".submit_button": I18n.t("getting_file", "Retrieving File...")

      return
