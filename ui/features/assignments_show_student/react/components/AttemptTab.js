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

import {Alert} from '@instructure/ui-alerts'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import axios from '@canvas/axios'
import LazyLoad, {lazy} from '@canvas/lazy-load'

import {bool, func, string} from 'prop-types'
import {EXTERNAL_TOOLS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {ExternalTool} from '@canvas/assignments/graphql/student/ExternalTool'
import ExternalToolOptions from './ExternalToolOptions'
import {Flex} from '@instructure/ui-flex'
import {friendlyTypeName, isSubmitted} from '../helpers/SubmissionHelpers'
import {
  IconAnnotateLine,
  IconAttachMediaLine,
  IconLinkLine,
  IconUploadLine,
  IconTextLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import LockedAssignment from './LockedAssignment'
import React, {Component} from 'react'
import StudentViewContext from './Context'
import SubmissionTypeButton from './SubmissionTypeButton'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Text} from '@instructure/ui-text'
import {uploadFile} from '@canvas/upload-file'
import {useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'
import theme from '@instructure/canvas-theme'
import {isOriginalityReportVisible} from '@canvas/grading/originalityReportHelper'

const I18n = useI18nScope('assignments_2_attempt_tab')

const ExternalToolSubmission = lazy(() =>
  import(
    /* webpackChunkName: "ExternalToolSubmission" */
    /* webpackPrefetch: true */
    './AttemptType/ExternalToolSubmission'
  )
)
const FilePreview = lazy(() =>
  import(
    /* webpackChunkName: "FilePreview" */
    /* webpackPrefetch: true */
    './AttemptType/FilePreview'
  )
)
const FileUpload = lazy(() =>
  import(
    /* webpackChunkName: "FileUpload" */
    /* webpackPrefetch: true */
    './AttemptType/FileUpload'
  )
)
const MediaAttempt = lazy(() =>
  import(
    /* webpackChunkName: "MediaAttempt" */
    /* webpackPrefetch: true */
    './AttemptType/MediaAttempt'
  )
)
const TextEntry = lazy(() =>
  import(
    /* webpackChunkName: "TextEntry" */
    /* webpackPrefetch: true */
    './AttemptType/TextEntry'
  )
)
const UrlEntry = lazy(() =>
  import(
    /* webpackChunkName: "UrlEntry" */
    /* webpackPrefetch: true */
    './AttemptType/UrlEntry'
  )
)
const StudentAnnotationAttempt = lazy(() =>
  import(
    /* webpackChunkName: "StudentAnnotationAttempt" */
    /* webpackPrefetch: true */
    './AttemptType/StudentAnnotationAttempt'
  )
)

const iconsByType = {
  media_recording: IconAttachMediaLine,
  online_text_entry: IconTextLine,
  online_upload: IconUploadLine,
  online_url: IconLinkLine,
  student_annotation: IconAnnotateLine,
}

function SubmissionTypeSelector({
  assignment,
  activeSubmissionType,
  selectedExternalTool,
  updateActiveSubmissionType,
}) {
  const {data, loading: loadingExternalTools} = useQuery(EXTERNAL_TOOLS_QUERY, {
    variables: {courseID: assignment.env.courseId},
  })

  const externalTools = data?.course?.externalToolsConnection.nodes || []
  const externalToolOptions = loadingExternalTools ? (
    <Flex.Item>
      <LoadingIndicator />
    </Flex.Item>
  ) : (
    <ExternalToolOptions
      activeSubmissionType={activeSubmissionType}
      externalTools={data?.course?.externalToolsConnection?.nodes || []}
      selectedExternalTool={selectedExternalTool}
      updateActiveSubmissionType={updateActiveSubmissionType}
    />
  )

  const multipleSubmissionTypes =
    assignment.submissionTypes.length > 1 ||
    (assignment.submissionTypes.includes('online_upload') && externalTools.length > 0)

  if (!multipleSubmissionTypes) {
    return null
  }

  return (
    <StudentViewContext.Consumer>
      {context => (
        <View as="div" data-testid="submission-type-selector" margin="0 auto small">
          <Text as="p" weight="bold">
            {context.isObserver
              ? I18n.t('Available submission types')
              : I18n.t('Choose a submission type')}
          </Text>

          <Flex wrap="wrap">
            {assignment.submissionTypes.map(type => (
              <Flex.Item as="div" key={type} margin="0 medium 0 0" data-testid={type}>
                <SubmissionTypeButton
                  displayName={friendlyTypeName(type)}
                  icon={iconsByType[type]}
                  selected={activeSubmissionType === type}
                  onSelected={() => {
                    updateActiveSubmissionType(type)
                  }}
                />
              </Flex.Item>
            ))}

            {assignment.submissionTypes.includes('online_upload') && externalToolOptions}
          </Flex>
        </View>
      )}
    </StudentViewContext.Consumer>
  )
}

function GroupSubmissionReminder({groupSet}) {
  return (
    <Alert variant="warning" margin="medium 0">
      {I18n.t('Keep in mind, this submission will count for everyone in your %{groupName} group.', {
        groupName: groupSet.name,
      })}
    </Alert>
  )
}

export default class AttemptTab extends Component {
  static propTypes = {
    activeSubmissionType: string,
    assignment: Assignment.shape.isRequired,
    createSubmissionDraft: func,
    focusAttemptOnInit: bool.isRequired,
    onContentsChanged: func,
    originalityReportsForA2: bool,
    selectedExternalTool: ExternalTool.shape,
    submission: Submission.shape.isRequired,
    updateActiveSubmissionType: func,
    updateEditingDraft: func,
    updateUploadingFiles: func,
    uploadingFiles: bool,
  }

  state = {
    filesToUpload: [],
    mediaRecordingIframURL: '',
  }

  renderFileUpload = () => {
    return (
      <LazyLoad errorCategory="Assignments 2 FileUpload on AttemptTab">
        <FileUpload
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          filesToUpload={this.state.filesToUpload}
          focusOnInit={this.props.focusAttemptOnInit}
          submission={this.props.submission}
          onCanvasFileRequested={this.onCanvasFileRequested}
          onUploadRequested={this.onUploadRequested}
        />
      </LazyLoad>
    )
  }

  onCanvasFileRequested = ({fileID, onError}) => {
    this.updateUploadingFiles(async () => {
      try {
        await this.createFileUploadSubmissionDraft([fileID])
      } catch (err) {
        onError()
      }
    })
  }

  onUploadRequested = ({files, onSuccess, onError}) => {
    this.setState(
      {
        filesToUpload: files.map((file, i) => {
          // "text" is filename in LTI Content Item
          const name = file.name || file.text || file.url
          const _id = `${i}-${file.url || file.name}`

          // As we receive progress events for this upload, we'll update the
          // "loaded and "total" values. Set some placeholder values so that
          // we start at 0%.
          return {_id, index: i, isLoading: true, name, loaded: 0, total: 1}
        }),
      },
      onSuccess
    )
    this.updateUploadingFiles(async () => {
      try {
        const newFiles = await this.uploadFiles(files)
        await this.createFileUploadSubmissionDraft(newFiles.map(file => file.id))
      } catch (err) {
        onError()
      } finally {
        this.setState({filesToUpload: []})
      }
    })
  }

  createFileUploadSubmissionDraft = async newFileIDs => {
    const {submission} = this.props
    const existingAttachments = submission?.submissionDraft?.attachments || []

    await this.props.createSubmissionDraft({
      variables: {
        id: submission.id,
        activeSubmissionType: 'online_upload',
        attempt: submission.attempt || 1,
        fileIds: existingAttachments.map(file => file._id).concat(newFileIDs),
      },
    })
  }

  updateUploadingFiles = async wrappedFunc => {
    this.props.updateUploadingFiles(true)
    await wrappedFunc()
    this.props.updateUploadingFiles(false)
  }

  uploadFiles = async files => {
    // This is taken almost verbatim from the uploadFiles method in the
    // upload-file module.  Rather than calling that method, we call uploadFile
    // for each file to track progress for the individual uploads.
    const {assignment} = this.props
    const uploadUrl =
      assignment.groupSet?.currentGroup == null
        ? `/api/v1/courses/${assignment.env.courseId}/assignments/${assignment._id}/submissions/${assignment.env.currentUser.id}/files`
        : `/api/v1/groups/${assignment.groupSet.currentGroup._id}/files`

    const uploadPromises = []
    files.forEach((file, i) => {
      const onProgress = event => {
        const {loaded, total} = event
        this.updateUploadProgress({index: i, loaded, total})
      }

      let promise
      if (file.url) {
        // LTI content item
        promise = uploadFile(
          uploadUrl,
          {
            url: file.url,
            name: file.text,
            content_type: file.mediaType,
            submit_assignment: false,
          },
          null,
          axios,
          onProgress
        )
      } else {
        promise = uploadFile(
          uploadUrl,
          {
            name: file.name,
            content_type: file.type,
            submit_assignment: true,
          },
          file,
          axios,
          onProgress
        )
      }
      uploadPromises.push(promise)
    })

    return Promise.all(uploadPromises)
  }

  updateUploadProgress = ({index, loaded, total}) => {
    this.setState(state => {
      const filesToUpload = [...state.filesToUpload]
      filesToUpload[index] = {...filesToUpload[index], loaded, total}
      return {filesToUpload}
    })
  }

  renderFileAttempt = () => {
    return isSubmitted(this.props.submission) ? (
      <LazyLoad errorCategory="Assignments 2 FilePreview on AttemptTab">
        <FilePreview
          submission={this.props.submission}
          isOriginalityReportVisible={
            isOriginalityReportVisible(
              this.props.assignment.originalityReportVisibility,
              this.props.assignment.dueAt,
              this.props.submission.gradingStatus
            ) && this.props.originalityReportsForA2
          }
        />
      </LazyLoad>
    ) : (
      this.renderFileUpload()
    )
  }

  renderTextAttempt = context => {
    const readOnly =
      (!context.allowChangesToSubmission && !context.isObserver) ||
      isSubmitted(this.props.submission)
    return (
      <LazyLoad errorCategory="Assignments 2 TextEntry on AttemptTab">
        <TextEntry
          createSubmissionDraft={this.props.createSubmissionDraft}
          focusOnInit={this.props.focusAttemptOnInit}
          onContentsChanged={this.props.onContentsChanged}
          readOnly={readOnly}
          submission={this.props.submission}
          updateEditingDraft={this.props.updateEditingDraft}
        />
      </LazyLoad>
    )
  }

  renderUrlAttempt = () => {
    return (
      <LazyLoad errorCategory="Assignments 2 UrlEntry on AttemptTab">
        <UrlEntry
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          focusOnInit={this.props.focusAttemptOnInit}
          submission={this.props.submission}
          updateEditingDraft={this.props.updateEditingDraft}
        />
      </LazyLoad>
    )
  }

  renderMediaAttempt = () => {
    return (
      <LazyLoad errorCategory="Assignments 2 MediaAttempt on AttemptTab">
        <MediaAttempt
          key={this.props.submission.attempt}
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
          focusOnInit={this.props.focusAttemptOnInit}
          submission={this.props.submission}
          updateUploadingFiles={this.props.updateUploadingFiles}
          uploadingFiles={this.props.uploadingFiles}
          iframeURL={this.state.mediaRecordingIframURL}
          setIframeURL={this.setMediaRecordingIframeURL}
        />
      </LazyLoad>
    )
  }

  setMediaRecordingIframeURL = url => {
    this.setState({mediaRecordingIframURL: url})
  }

  renderStudentAnnotationAttempt = () => {
    return (
      <LazyLoad errorCategory="Assignments 2 StudentAnnotationAttempt on AttemptTab">
        <StudentAnnotationAttempt
          submission={this.props.submission}
          assignment={this.props.assignment}
          createSubmissionDraft={this.props.createSubmissionDraft}
        />
      </LazyLoad>
    )
  }

  renderExternalToolAttempt = externalTool => (
    <LazyLoad errorCategory="Assignments 2 ExternalToolSubmission on AttemptTab">
      <ExternalToolSubmission
        createSubmissionDraft={this.props.createSubmissionDraft}
        onFileUploadRequested={({files}) => {
          this.onUploadRequested({
            files,
            onSuccess: () => {
              // If an LTI returns a file attachment and not a link,
              // switch to the upload panel to show it
              this.props.updateActiveSubmissionType('online_upload')
            },
          })
        }}
        submission={this.props.submission}
        tool={externalTool}
      />
    </LazyLoad>
  )

  renderByType(submissionType, context, externalTool) {
    switch (submissionType) {
      case 'media_recording':
        return this.renderMediaAttempt()
      case 'online_text_entry':
        return this.renderTextAttempt(context)
      case 'online_upload':
        return this.renderFileAttempt()
      case 'online_url':
        return this.renderUrlAttempt()
      case 'student_annotation':
        return this.renderStudentAnnotationAttempt()
      case 'basic_lti_launch':
        return this.renderExternalToolAttempt(externalTool)
      default:
        throw new Error('submission type not yet supported in A2')
    }
  }

  render() {
    const {assignment, submission} = this.props
    if (assignment.lockInfo.isLocked && !isSubmitted(submission)) {
      return <LockedAssignment assignment={assignment} />
    }

    const submissionType = isSubmitted(submission)
      ? submission.submissionType
      : this.props.activeSubmissionType

    let selectedType
    if (
      submissionType != null &&
      (assignment.submissionTypes.includes(submissionType) || submissionType === 'basic_lti_launch')
    ) {
      selectedType = submissionType
    } else if (assignment.submissionTypes.length === 1) {
      selectedType = assignment.submissionTypes[0]
    }

    if (
      submission.submissionType !== null &&
      submission.submissionType !== selectedType &&
      submission.submissionStatus === 'submitted'
    ) {
      selectedType = submission.submissionType
    }

    const submittingForGroup =
      assignment.groupSet != null &&
      !assignment.gradeGroupStudentsIndividually &&
      !isSubmitted(submission)

    return (
      <StudentViewContext.Consumer>
        {context => (
          <div data-testid="attempt-tab">
            {submittingForGroup && context.allowChangesToSubmission && (
              <GroupSubmissionReminder groupSet={assignment.groupSet} />
            )}

            {(context.allowChangesToSubmission || context.isObserver) &&
              !isSubmitted(submission) && (
                <SubmissionTypeSelector
                  activeSubmissionType={this.props.activeSubmissionType}
                  assignment={assignment}
                  selectedExternalTool={this.props.selectedExternalTool}
                  submission={submission}
                  updateActiveSubmissionType={this.props.updateActiveSubmissionType}
                />
              )}

            {selectedType != null && (
              <div
                style={{
                  backgroundColor: theme.variables.colors.backgroundLight,
                  borderTop: `2px solid ${theme.variables.colors.borderMedium}`,
                }}
              >
                {this.renderByType(selectedType, context, this.props.selectedExternalTool)}
              </div>
            )}
          </div>
        )}
      </StudentViewContext.Consumer>
    )
  }
}
