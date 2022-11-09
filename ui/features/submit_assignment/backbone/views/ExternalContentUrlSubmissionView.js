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
import template from '../../jst/ExternalContentHomeworkUrlSubmissionView.handlebars'
import ExternalContentHomeworkSubmissionView from './ExternalContentHomeworkSubmissionView'

class ExternalContentUrlSubmissionView extends ExternalContentHomeworkSubmissionView {
  constructor(...args) {
    super(...args)
    this.submitHomework = this.submitHomework.bind(this)
    this.redirectSuccessfulAssignment = this.redirectSuccessfulAssignment.bind(this)
  }

  submitHomework() {
    const data = {
      submission: {
        submission_type: 'online_url',
        url: this.model.get('url'),
      },
      comment: {
        text_comment: this.model.get('comment'),
      },
    }

    const submissionUrl = `/api/v1/courses/${ENV.COURSE_ID}/assignments/${ENV.SUBMIT_ASSIGNMENT.ID}/submissions`
    return $.ajaxJSON(submissionUrl, 'POST', data, this.redirectSuccessfulAssignment)
  }

  redirectSuccessfulAssignment(_responseData) {
    $(window).off('beforeunload') // remove alert message from being triggered
    return window.location.reload()
  }
}

ExternalContentUrlSubmissionView.prototype.template = template
ExternalContentUrlSubmissionView.optionProperty('externalTool')

export default ExternalContentUrlSubmissionView
