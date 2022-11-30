//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/ExternalContentHomeworkFileSubmissionView.handlebars'
import ExternalContentHomeworkSubmissionView from './ExternalContentHomeworkSubmissionView'

const I18n = useI18nScope('ExternalContentFileSubmissionView')

class ExternalContentFileSubmissionView extends ExternalContentHomeworkSubmissionView {
  constructor(...args) {
    super(...args)
    this.submitHomework = this.submitHomework.bind(this)
    this.reloadSuccessfulAssignment = this.reloadSuccessfulAssignment.bind(this)
    this.sendCallbackUrl = this.sendCallbackUrl.bind(this)
    this.disableLoader = this.disableLoader.bind(this)
    this.submissionFailure = this.submissionFailure.bind(this)
  }

  submitHomework() {
    return this.uploadFileFromUrl(this.externalTool, this.model)
  }

  reloadSuccessfulAssignment(_responseData) {
    $(window).off('beforeunload') // remove alert message from being triggered
    // eslint-disable-next-line no-alert
    window.alert(
      I18n.t(
        'processing_submission',
        'Canvas is currently processing your submission. You can safely navigate away from this page and we will email you if the submission fails to process.'
      )
    )
    window.location.reload()
    this.loaderPromise.resolve()
  }

  sendCallbackUrl(responseData) {
    const uploadUrl = responseData.data.upload_url
    if (uploadUrl) {
      const formData = new FormData()
      const uploadParams = responseData.data.upload_params

      if (uploadParams) {
        for (const key in uploadParams) {
          formData.append(key, uploadParams[key])
        }
      }

      return axios.post(uploadUrl, formData)
    }
  }

  disableLoader() {
    return this.loaderPromise.resolve()
  }

  submissionFailure() {
    this.loaderPromise.resolve()
    this.$el.find('.submit_button').text(I18n.t('file_retrieval_error', 'Retrieving File Failed'))
    return $.flashError(
      I18n.t(
        'invalid_file_retrieval',
        'There was a problem retrieving the file sent from this tool.'
      )
    )
  }

  uploadFileFromUrl(tool, modelData) {
    let preflightUrl
    this.loaderPromise = $.Deferred()

    this.assignmentSubmission = modelData
    // build the params for submitting the assignment
    const preflightData = {
      url: this.assignmentSubmission.get('url'),
      name: this.assignmentSubmission.get('text'),
      content_type: '',
      eula_agreement_timestamp: this.assignmentSubmission.get('eula_agreement_timestamp'),
      comment: this.assignmentSubmission.get('comment'),
    }

    const gid = ENV.SUBMIT_ASSIGNMENT.GROUP_ID_FOR_USER
    if (gid !== null && typeof gid !== 'undefined') {
      preflightUrl = `/api/v1/groups/${gid}/files?assignment_id=${ENV.SUBMIT_ASSIGNMENT.ID}&submit_assignment=1`
    } else {
      preflightUrl = `/api/v1/courses/${ENV.COURSE_ID}/assignments/${ENV.SUBMIT_ASSIGNMENT.ID}/submissions/${ENV.current_user_id}/files`
    }

    axios
      .post(preflightUrl, preflightData)
      .then(this.sendCallbackUrl)
      .then(this.reloadSuccessfulAssignment)
      .catch(this.submissionFailure)

    this.$el.disableWhileLoading(this.loaderPromise, {
      buttons: {
        '.submit_button': I18n.t('getting_file', 'Retrieving File...'),
      },
    })
  }
}

ExternalContentFileSubmissionView.prototype.template = template
ExternalContentFileSubmissionView.optionProperty('externalTool')

export default ExternalContentFileSubmissionView
