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
import {bool, func, string} from 'prop-types'
import {FormField} from '@instructure/ui-form-field'
import I18n from 'i18n!assignments_2_attempt_tab'
import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {Component, lazy, Suspense} from 'react'
import {Submission} from '../graphqlData/Submission'
import SubmissionChoiceSVG from '../SVG/SubmissionChoice.svg'
import SVGWithTextPlaceholder from '../../shared/SVGWithTextPlaceholder'
import {Text} from '@instructure/ui-elements'

const FilePreview = lazy(() => import('./AttemptType/FilePreview'))
const FileUpload = lazy(() => import('./AttemptType/FileUpload'))
const MediaAttempt = lazy(() => import('./AttemptType/MediaAttempt'))
const TextEntry = lazy(() => import('./AttemptType/TextEntry'))
const UrlEntry = lazy(() => import('./AttemptType/UrlEntry'))

export default class AttemptTab extends Component {
  static propTypes = {
    activeSubmissionType: string,
    assignment: Assignment.shape,
    createSubmissionDraft: func,
    editingDraft: bool,
    submission: Submission.shape,
    updateActiveSubmissionType: func,
    updateEditingDraft: func,
    updateUploadingFiles: func,
    uploadingFiles: bool
  }

  friendlyTypeName = type => {
    switch (type) {
      case 'media_recording':
        return I18n.t('Media')
      case 'online_text_entry':
        return I18n.t('Text Entry')
      case 'online_upload':
        return I18n.t('File')
      case 'online_url':
        return I18n.t('URL')
      default:
        throw new Error('submission type not yet supported in A2')
    }
  }

  getCurrentSubmissionType = () => {
    if (this.props.submission.url !== null) {
      return 'online_url'
    } else if (this.props.submission.body !== null && this.props.submission.body !== '') {
      return 'online_text_entry'
    } else if (this.props.submission.attachments.length !== 0) {
      return 'online_upload'
    }
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

  renderTextAttempt = () => {
    return (
      <Suspense fallback={<LoadingIndicator />}>
        <TextEntry
          createSubmissionDraft={this.props.createSubmissionDraft}
          editingDraft={this.props.editingDraft}
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
        <MediaAttempt assignment={this.props.assignment} />
      </Suspense>
    )
  }

  renderByType(submissionType) {
    switch (submissionType) {
      case 'media_recording':
        return this.renderMediaAttempt()
      case 'online_text_entry':
        return this.renderTextAttempt()
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
              {this.friendlyTypeName(type)}
            </option>
          ))}
        </select>
      </FormField>
    )
  }

  render() {
    if (this.props.assignment.submissionTypes.length > 1) {
      const submissionType = ['submitted', 'graded'].includes(this.props.submission.state)
        ? this.getCurrentSubmissionType()
        : this.props.activeSubmissionType
      return (
        <div data-testid="attempt-tab">
          {this.renderSubmissionTypeSelector()}
          {this.submissionType !== null &&
          this.props.assignment.submissionTypes.includes(submissionType)
            ? this.renderByType(submissionType)
            : this.renderUnselectedType()}
        </div>
      )
    } else {
      return (
        <div data-testid="attempt-tab">
          {this.renderByType(this.props.assignment.submissionTypes[0])}
        </div>
      )
    }
  }
}
