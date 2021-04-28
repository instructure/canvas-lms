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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {friendlyTypeName, getCurrentSubmissionType} from '../helpers/SubmissionHelpers'
import {
  IconAttachMediaLine,
  IconLinkLine,
  IconUploadLine,
  IconTextLine
} from '@instructure/ui-icons'
import I18n from 'i18n!assignments_2_attempt_tab'
import LoadingIndicator from '@canvas/loading-indicator'
import LockedAssignment from './LockedAssignment'
import React, {Component, lazy, Suspense} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const FilePreview = lazy(() => import('./AttemptType/FilePreview'))
const FileUpload = lazy(() => import('./AttemptType/FileUpload'))
const MediaAttempt = lazy(() => import('./AttemptType/MediaAttempt'))
const TextEntry = lazy(() => import('./AttemptType/TextEntry'))
const UrlEntry = lazy(() => import('./AttemptType/UrlEntry'))

const iconsByType = {
  media_recording: IconAttachMediaLine,
  online_text_entry: IconTextLine,
  online_upload: IconUploadLine,
  online_url: IconLinkLine
}

function SubmissionTypeButton({displayName, icon: Icon, selected, onSelected}) {
  const foregroundColor = selected ? 'primary-inverse' : 'brand'
  const screenReaderText = selected
    ? I18n.t('Submission type %{displayName}, currently selected', {displayName})
    : I18n.t('Select submission type %{displayName}', {displayName})

  return (
    <View
      as="div"
      className="submission-type-icon-contents"
      background={selected ? 'brand' : 'primary'}
      borderColor="brand"
      borderWidth="small"
      borderRadius="medium"
      height="80px"
      minWidth="90px"
    >
      <Button
        display="block"
        interaction={selected ? 'readonly' : 'enabled'}
        onClick={onSelected}
        theme={{borderWidth: '0'}}
        withBackground={false}
      >
        <Icon size="small" color={foregroundColor} />
        <View as="div" margin="small 0 0">
          <ScreenReaderContent>{screenReaderText}</ScreenReaderContent>
          <Text color={foregroundColor} weight="normal" size="medium">
            {displayName}
          </Text>
        </View>
      </Button>
    </View>
  )
}

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

  renderSubmissionTypeSelector() {
    // because we are currently allowing only a single submission type
    // you should never need to change types after submitting
    if (this.props.submission.state === 'graded' || this.props.submission.state === 'submitted') {
      return null
    }

    return (
      <View as="div" data-testid="submission-type-selector" margin="0 auto small">
        <Text as="p" weight="bold">
          {I18n.t('Choose a submission type')}
        </Text>

        <Flex>
          {this.props.assignment.submissionTypes.map(type => (
            <Flex.Item as="div" key={type} margin="0 medium 0 0">
              <SubmissionTypeButton
                displayName={friendlyTypeName(type)}
                icon={iconsByType[type]}
                selected={this.props.activeSubmissionType === type}
                onSelected={() => {
                  this.props.updateActiveSubmissionType(type)
                }}
              />
            </Flex.Item>
          ))}
        </Flex>
      </View>
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

            {selectedType != null && this.renderByType(selectedType, context)}
          </div>
        )}
      </StudentViewContext.Consumer>
    )
  }
}
