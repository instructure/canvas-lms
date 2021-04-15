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

import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {bool, func, string} from 'prop-types'
import {FormField} from '@instructure/ui-form-field'
import {friendlyTypeName, getCurrentSubmissionType} from '../helpers/SubmissionHelpers'
import I18n from 'i18n!assignments_2_attempt_tab'
import LoadingIndicator from '@canvas/loading-indicator'
import LockedAssignment from './LockedAssignment'
import React, {Component, lazy, Suspense} from 'react'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import SubmissionChoiceSVG from '../../images/SubmissionChoice.svg'
import SVGWithTextPlaceholder from '../SVGWithTextPlaceholder'
import {Text} from '@instructure/ui-text'

const FilePreview = lazy(() => import('./AttemptType/FilePreview'))
const FileUpload = lazy(() => import('./AttemptType/FileUpload'))
const MediaAttempt = lazy(() => import('./AttemptType/MediaAttempt'))
const TextEntry = lazy(() => import('./AttemptType/TextEntry'))
const UrlEntry = lazy(() => import('./AttemptType/UrlEntry'))

export default class AttemptTab extends Component {
  static propTypes = {
    activeSubmissionType: string,
    assignment: Assignment.shape.isRequired,
    createSubmissionDraft: func,
    editingDraft: bool,
    onContentsChanged: func,
    submission: Submission.shape.isRequired,
    updateActiveSubmissionType: func,
    updateEditingDraft: func,
    updateUploadingFiles: func,
    uploadingFiles: bool
  }

  renderFileUpload = () => {
    return (
      <Suspense fallback={<LoadingIndicator />}>
        <FileUpload
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          submission={this.props.submission}
          updateUploadingFiles={this.props.updateUploadingFiles}
          uploadingFiles={this.props.uploadingFiles}
        />
      </Suspense>
    )
  }

  renderFileAttempt = () => {
    return this.props.submission.state === 'graded' ||
      this.props.submission.state === 'submitted' ? (
      <Suspense fallback={<LoadingIndicator />}>
        <FilePreview
          key={this.props.submission.attempt}
          files={this.props.submission.attachments}
        />
      </Suspense>
    ) : (
      this.renderFileUpload()
    )
  }

  renderTextAttempt = context => {
    const readOnly =
      !context.allowChangesToSubmission ||
      ['submitted', 'graded'].includes(this.props.submission.state)

    return (
      <Suspense fallback={<LoadingIndicator />}>
        <TextEntry
          createSubmissionDraft={this.props.createSubmissionDraft}
          onContentsChanged={this.props.onContentsChanged}
          readOnly={readOnly}
          submission={this.props.submission}
          updateEditingDraft={this.props.updateEditingDraft}
        />
      </Suspense>
    )
  }

  renderUrlAttempt = () => {
    return (
      <Suspense fallback={<LoadingIndicator />}>
        <UrlEntry
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          submission={this.props.submission}
          updateEditingDraft={this.props.updateEditingDraft}
        />
      </Suspense>
    )
  }

  renderMediaAttempt = () => {
    return (
      <Suspense fallback={<LoadingIndicator />}>
        <MediaAttempt
          key={this.props.submission.attempt}
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          submission={this.props.submission}
          updateUploadingFiles={this.props.updateUploadingFiles}
          uploadingFiles={this.props.uploadingFiles}
        />
      </Suspense>
    )
  }

  renderByType(submissionType, context) {
    switch (submissionType) {
      case 'media_recording':
        return this.renderMediaAttempt()
      case 'online_text_entry':
        return this.renderTextAttempt(context)
      case 'online_upload':
        return this.renderFileAttempt()
      case 'online_url':
        return this.renderUrlAttempt()
      default:
        throw new Error('submission type not yet supported in A2')
    }
  }

  renderUnselectedType() {
    return (
      <SVGWithTextPlaceholder
        text={I18n.t('Choose One Submission Type')}
        url={SubmissionChoiceSVG}
      />
    )
  }

  renderSubmissionTypeSelector() {
    // because we are currently allowing only a single submission type
    // you should never need to change types after submitting
    if (this.props.submission.state === 'graded' || this.props.submission.state === 'submitted') {
      return null
    }

    return (
      <FormField
        id="select-submission-type"
        label={<Text weight="bold">{I18n.t('Submission Type')}</Text>}
      >
        <select
          onChange={event => this.props.updateActiveSubmissionType(event.target.value)}
          style={{
            margin: '0 0 10px 0',
            width: '225px'
          }}
          value={this.props.activeSubmissionType || 'default'}
        >
          <option hidden key="default" value="default">
            {I18n.t('Choose One')}
          </option>
          {this.props.assignment.submissionTypes.map(type => (
            <option key={type} value={type}>
              {friendlyTypeName(type)}
            </option>
          ))}
        </select>
      </FormField>
    )
  }

  render() {
    const {assignment, submission} = this.props
    if (assignment.lockInfo.isLocked && submission.state === 'unsubmitted') {
      return <LockedAssignment assignment={assignment} />
    }

    const submissionType = ['submitted', 'graded'].includes(submission.state)
      ? getCurrentSubmissionType(submission)
      : this.props.activeSubmissionType

    const multipleSubmissionTypes = assignment.submissionTypes.length > 1

    let selectedType
    if (multipleSubmissionTypes) {
      if (submissionType != null && assignment.submissionTypes.includes(submissionType)) {
        selectedType = submissionType
      }
    } else {
      selectedType = assignment.submissionTypes[0]
    }

    return (
      <StudentViewContext.Consumer>
        {context => (
          <div data-testid="attempt-tab">
            {multipleSubmissionTypes &&
              context.allowChangesToSubmission &&
              this.renderSubmissionTypeSelector()}

            {selectedType != null
              ? this.renderByType(selectedType, context)
              : context.allowChangesToSubmission && this.renderUnselectedType()}
          </div>
        )}
      </StudentViewContext.Consumer>
    )
  }
}
