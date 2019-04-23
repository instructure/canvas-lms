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
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Button from '@instructure/ui-buttons/lib/components/Button'
import {DEFAULT_ICON} from '../../../../shared/helpers/mimeClassIconHelper'
import FileList from '../../../shared/FileList'
import I18n from 'i18n!assignments_2'
import IconAudio from '@instructure/ui-icons/lib/Line/IconAudio'
import IconMedia from '@instructure/ui-icons/lib/Line/IconMedia'
import LoadingIndicator from '../../../shared/LoadingIndicator'
import React, {Component} from 'react'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import {submissionCommentAttachmentsUpload} from '../../../../shared/upload_file'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'

import {
  CREATE_SUBMISSION_COMMENT,
  StudentAssignmentShape,
  SUBMISSION_COMMENT_QUERY
} from '../../assignmentData'
import {Mutation} from 'react-apollo'

const ALERT_TIMEOUT = 5000

export default class CommentTextArea extends Component {
  static propTypes = {
    assignment: StudentAssignmentShape
  }

  state = {
    commentText: '',
    currentFiles: [],
    hasError: false,
    uploadingComments: false
  }

  queryVariables() {
    return {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionId: this.props.assignment.submissionsConnection.nodes[0].id.toString()
      }
    }
  }

  optimisticResponse() {
    return {
      createSubmissionComment: {
        submissionComment: {
          _id: 'pending',
          comment: this.state.commentText,
          updatedAt: new Date().toISOString(),
          attachments: [],
          author: {
            avatarUrl: this.props.assignment.env.currentUser.avatar_image_url,
            shortName: this.props.assignment.env.currentUser.display_name,
            __typename: 'User'
          },
          mediaObject: null, // When we handle upload of media comments we will handle this
          __typename: 'SubmissionComment'
        },
        __typename: 'CreateSubmissionCommentPayload'
      }
    }
  }

  updateSubmissionCommentCache = (cache, submission) => {
    const {submissionComments} = cache.readQuery(this.queryVariables())
    submissionComments.commentsConnection.nodes = submissionComments.commentsConnection.nodes.concat(
      [submission.data.createSubmissionComment.submissionComment]
    )
    cache.writeQuery({
      ...this.queryVariables(),
      data: {submissionComments}
    })
  }

  onTextChange = e => {
    this.setState({commentText: e.target.value})
  }

  onSendComment = createSubmissionComment => {
    this.setState({hasError: false, uploadingComments: true}, async () => {
      let attachmentIds = []

      if (this.state.currentFiles.length) {
        try {
          const attachments = await submissionCommentAttachmentsUpload(
            this.state.currentFiles,
            this.props.assignment.env.courseId,
            this.props.assignment._id
          )
          attachmentIds = attachments.map(attachment => attachment.id)
        } catch (err) {
          this.setState({hasError: true, uploadingComments: false})
          return
        }
      }

      await createSubmissionComment({
        variables: {
          id: this.props.assignment.submissionsConnection.nodes[0]._id,
          comment: this.state.commentText,
          fileIds: attachmentIds
        }
      })

      this.setState({commentText: '', currentFiles: [], uploadingComments: false})
    })
  }

  onFileSelected = event => {
    let currIndex = this.state.currentFiles.length
      ? this.state.currentFiles[this.state.currentFiles.length - 1].id
      : 0
    const filesArray = [...event.currentTarget.files]
    filesArray.forEach(file => {
      file.id = ++currIndex
    })
    this.setState(prevState => ({currentFiles: [...prevState.currentFiles, ...filesArray]}))
  }

  renderAlert(data, error) {
    return (
      <React.Fragment>
        {data && (
          <Alert
            screenReaderOnly
            liveRegion={() => document.getElementById('flash_screenreader_holder')}
            timeout={ALERT_TIMEOUT}
          >
            {I18n.t('Submission comment sent')}
          </Alert>
        )}
        {error && (
          <Alert variant="error" margin="small" timeout={ALERT_TIMEOUT}>
            {I18n.t('Error sending submission comment')}
          </Alert>
        )}
      </React.Fragment>
    )
  }

  handleRemoveFile = refsMap => e => {
    e.preventDefault()

    const refs = {}
    Object.entries(refsMap).forEach(([key, value]) => (refs[key] = value))

    const fileId = parseInt(e.currentTarget.id, 10)
    const fileIndex = this.state.currentFiles.findIndex(file => file.id === fileId)

    this.setState(
      prevState => ({
        currentFiles: prevState.currentFiles.filter((_, i) => i !== fileIndex)
      }),
      () => {
        if (this.state.currentFiles.length === 0) {
          this.attachmentFileButton.focus()
        } else if (fileIndex === 0) {
          refs[this.state.currentFiles[fileIndex].id].focus()
        } else {
          refs[this.state.currentFiles[fileIndex - 1].id].focus()
        }
      }
    )
  }

  render() {
    return (
      <Mutation
        optimisticResponse={this.optimisticResponse()}
        update={this.updateSubmissionCommentCache}
        mutation={CREATE_SUBMISSION_COMMENT}
      >
        {(createSubmissionComment, {data, error}) => (
          <div>
            {this.renderAlert(data, error || this.state.hasError)}
            <div>
              <TextArea
                label={<ScreenReaderContent>{I18n.t('Comment input box')}</ScreenReaderContent>}
                onChange={this.onTextChange}
                placeholder={I18n.t('Submit a Comment')}
                resize="both"
                value={this.state.commentText}
              />
              {this.state.uploadingComments && <LoadingIndicator />}
              {this.state.currentFiles.length !== 0 && !this.state.uploadingComments && (
                <div data-testid="assignments_2_comment_attachment">
                  <FileList
                    files={this.state.currentFiles}
                    removeFileHandler={this.handleRemoveFile}
                    canRemove
                  />
                </div>
              )}
            </div>
            {!this.state.uploadingComments && !this.state.hasError && (
              <div className="textarea-action-button-container">
                <input
                  id="attachmentFile"
                  ref={element => {
                    this.fileInput = element
                  }}
                  multiple
                  onChange={this.onFileSelected}
                  style={{
                    display: 'none'
                  }}
                  type="file"
                />
                <Button
                  id="attachmentFileButton"
                  icon={DEFAULT_ICON}
                  margin="0 x-small 0 0"
                  onClick={() => {
                    this.fileInput.click()
                  }}
                  ref={element => {
                    this.attachmentFileButton = element
                  }}
                  size="small"
                  variant="icon"
                >
                  <ScreenReaderContent>{I18n.t('Attach a File')}</ScreenReaderContent>
                </Button>
                <Button icon={IconMedia} margin="0 x-small 0 0" size="small" variant="icon">
                  <ScreenReaderContent>{I18n.t('Record Video')}</ScreenReaderContent>
                </Button>
                <Button icon={IconAudio} margin="0 x-small 0 0" size="small" variant="icon">
                  <ScreenReaderContent>{I18n.t('Record Audio')}</ScreenReaderContent>
                </Button>
                <Button
                  disabled={
                    this.state.commentText.length === 0 && this.state.currentFiles.length === 0
                  }
                  onClick={() => this.onSendComment(createSubmissionComment)}
                >
                  {I18n.t('Send Comment')}
                </Button>
              </div>
            )}
          </div>
        )}
      </Mutation>
    )
  }
}
