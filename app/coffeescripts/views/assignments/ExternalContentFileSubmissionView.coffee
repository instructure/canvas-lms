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
  'axios'
  'i18n!assignments'
  'jst/assignments/ExternalContentHomeworkFileSubmissionView'
  './ExternalContentHomeworkSubmissionView'
], ($, axios, I18n, template, ExternalContentHomeworkSubmissionView) ->

  class ExternalContentFileSubmissionView extends ExternalContentHomeworkSubmissionView
    template: template
    @optionProperty 'externalTool'

    submitHomework: =>
      @uploadFileFromUrl(@externalTool, @model)

    reloadSuccessfulAssignment: (responseData) =>
      $(window).off('beforeunload') # remove alert message from being triggered
      alert(
        I18n.t(
          "processing_submission",
          "Canvas is currently processing your submission. You can safely navigate away from this page and we will email you if the submission fails to process."
        )
      )
      window.location.reload()
      @loaderPromise.resolve()
      return

    sendCallbackUrl: (responseData) =>
      uploadUrl = responseData.data.upload_url
      if uploadUrl
        formData = new FormData
        uploadParams = responseData.data.upload_params

        if uploadParams
          for key of uploadParams
            formData.append(key, uploadParams[key])

        axios.post(uploadUrl, formData)

    disableLoader: =>
      @loaderPromise.resolve()

    submissionFailure: =>
      @loaderPromise.resolve()
      @$el.find(".submit_button").text I18n.t("file_retrieval_error", "Retrieving File Failed")
      $.flashError I18n.t("invalid_file_retrieval", "There was a problem retrieving the file sent from this tool.")

    uploadFileFromUrl: (tool, modelData) ->
      @loaderPromise = $.Deferred()

      @assignmentSubmission = modelData
      # build the params for submitting the assignment
      # TODO: The `submit_assignment` param is used to help in backwards compat for fixing auto submissions,
      # can be removed in the next release.
      preflightData =
        url: @assignmentSubmission.get('url')
        name: @assignmentSubmission.get('text')
        content_type: ''
        submit_assignment: true
        eula_agreement_timestamp: @assignmentSubmission.get('eula_agreement_timestamp')

      if ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER?
        preflightUrl = "/api/v1/groups/" + ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER + "/files"
      else
        preflightUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions/" + ENV.current_user_id + "/files"

      axios.post(preflightUrl, preflightData)
        .then(@sendCallbackUrl)
        .then(@reloadSuccessfulAssignment)
        .catch(@submissionFailure)

      @$el.disableWhileLoading @loaderPromise,
        buttons:
          ".submit_button": I18n.t("getting_file", "Retrieving File...")

      return
