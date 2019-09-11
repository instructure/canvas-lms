/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {Assignment} from '../graphqlData/Assignment'
import {bool, func} from 'prop-types'
import FilePreview from './AttemptType/FilePreview'
import FileUpload from './AttemptType/FileUpload'
import MediaAttempt from './AttemptType/MediaAttempt'
import React, {Component} from 'react'
import {Submission} from '../graphqlData/Submission'
import TextEntry from './AttemptType/TextEntry'

export default class AttemptTab extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    createSubmissionDraft: func,
    editingDraft: bool,
    submission: Submission.shape,
    updateEditingDraft: func,
    updateUploadingFiles: func,
    uploadingFiles: bool
  }

  renderFileUpload = () => {
    return (
      <FileUpload
        assignment={this.props.assignment}
        createSubmissionDraft={this.props.createSubmissionDraft}
        submission={this.props.submission}
        updateUploadingFiles={this.props.updateUploadingFiles}
        uploadingFiles={this.props.uploadingFiles}
      />
    )
  }

  renderFileAttempt = () => {
    return this.props.submission.state === 'graded' ||
      this.props.submission.state === 'submitted' ? (
      <FilePreview key={this.props.submission.attempt} files={this.props.submission.attachments} />
    ) : (
      this.renderFileUpload()
    )
  }

  renderTextAttempt = () => {
    return (
      <TextEntry
        createSubmissionDraft={this.props.createSubmissionDraft}
        editingDraft={this.props.editingDraft}
        submission={this.props.submission}
        updateEditingDraft={this.props.updateEditingDraft}
      />
    )
  }

  renderMediaAttempt = () => {
    return <MediaAttempt assignment={this.props.assignment} />
  }

  renderByType() {
    // TODO: we need to ensure we handle multiple submission types eventually
    switch (this.props.assignment.submissionTypes[0]) {
      case 'media_recording':
        return this.renderMediaAttempt()
      case 'online_text_entry':
        return this.renderTextAttempt()
      case 'online_upload':
        return this.renderFileAttempt()
      default:
        throw new Error('submission type not yet supported in A2')
    }
  }

  render() {
    return <div data-testid="attempt-tab">{this.renderByType()}</div>
  }
}
