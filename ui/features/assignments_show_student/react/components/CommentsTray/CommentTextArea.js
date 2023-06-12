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

import {useScope as useI18nScope} from '@canvas/i18n'
import {IconAttachMediaLine} from '@instructure/ui-icons'
import {Mutation} from 'react-apollo'
import React, {Component} from 'react'
import {bool} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import UploadMedia from '@instructure/canvas-media'

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {Button, IconButton} from '@instructure/ui-buttons'
import {CREATE_SUBMISSION_COMMENT} from '@canvas/assignments/graphql/student/Mutations'
import {DEFAULT_ICON} from '@canvas/mime/react/mimeClassIconHelper'
import FileList from '../../FileList'
import LoadingIndicator from '@canvas/loading-indicator'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {submissionCommentAttachmentsUpload} from '@canvas/upload-file'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {UploadMediaStrings, MediaCaptureStrings} from '@canvas/upload-media-translations'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'

const I18n = useI18nScope('assignments_2')

export default class CommentTextArea extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    submission: Submission.shape,
    reviewerSubmission: Submission.shape,
    isPeerReviewEnabled: bool,
    onSendCommentSuccess: () => {},
  }

  state = {
    commentText: '',
    currentFiles: [],
    hasError: false,
    mediaModalOpen: false,
    mediaObject: null,
    uploadingComments: false,
  }

  queryVariables() {
    return {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionId: this.props.submission.id,
        submissionAttempt: this.props.submission.attempt,
        peerReview: this.props.isPeerReviewEnabled,
      },
    }
  }

  optimisticResponse() {
    return {
      createSubmissionComment: {
        errors: null,
        submissionComment: {
          _id: 'pending',
          attachments: [],
          comment: this.state.commentText,
          read: true,
          updatedAt: new Date().toISOString(),
          author: {
            avatarUrl: this.props.assignment.env.currentUser.avatar_image_url,
            shortName: this.props.assignment.env.currentUser.display_name,
            __typename: 'User',
          },
          mediaObject: null, // When we handle upload of media comments we will handle this
          __typename: 'SubmissionComment',
        },
        __typename: 'CreateSubmissionCommentPayload',
      },
    }
  }

  updateSubmissionCommentCache = (cache, result) => {
    if (result.data.createSubmissionComment.errors) {
      return
    }

    const {submissionComments} = JSON.parse(JSON.stringify(cache.readQuery(this.queryVariables())))
    submissionComments.commentsConnection.nodes =
      submissionComments.commentsConnection.nodes.concat([
        result.data.createSubmissionComment.submissionComment,
      ])
    cache.writeQuery({
      ...this.queryVariables(),
      data: {submissionComments},
    })
  }

  onFileSelected = event => {
    let currIndex = this.state.currentFiles.length
      ? this.state.currentFiles[this.state.currentFiles.length - 1].id
      : 0
    const selectedFiles = [...event.currentTarget.files]
    selectedFiles.forEach(file => {
      file.id = ++currIndex
    })
    this.setState(prevState => ({currentFiles: [...prevState.currentFiles, ...selectedFiles]}))
  }

  onMediaModalDismiss = (err, mediaObject) => {
    if (!err && !mediaObject) {
      this.setState({mediaModalOpen: false})
    } else if (err) {
      // TODO handle error
      throw new Error(err)
    } else {
      mediaObject.type = 'video/mp4'
      mediaObject.name = mediaObject.media_object.title
      let currIndex = this.state.currentFiles.length
        ? this.state.currentFiles[this.state.currentFiles.length - 1].id
        : 0
      mediaObject.id = ++currIndex
      this.setState(prevState => ({
        mediaModalOpen: false,
        mediaObject,
        currentFiles: [...prevState.currentFiles, mediaObject],
      }))
    }
  }

  onSendComment = createSubmissionComment => {
    this.setState({hasError: false, uploadingComments: true}, async () => {
      const mediaObject = this.state.mediaObject || {
        media_object: {media_id: null, media_type: null},
      }
      let attachmentIds = []
      const filesWithoutMediaObject = this.state.currentFiles.filter(
        file => file !== this.state.mediaObject
      )

      if (filesWithoutMediaObject.length) {
        try {
          const attachments = await submissionCommentAttachmentsUpload(
            filesWithoutMediaObject,
            this.props.assignment.env.courseId,
            this.props.assignment._id
          )
          attachmentIds = attachments.map(attachment => attachment.id)
        } catch (err) {
          this.setState({hasError: true, uploadingComments: false})
          this.context.setOnFailure(I18n.t('Error sending submission comment'))
          return
        }
      }

      await createSubmissionComment({
        variables: {
          id: this.props.submission.id,
          submissionAttempt: this.props.submission.attempt,
          comment: this.state.commentText,
          fileIds: attachmentIds,
          mediaObjectId: mediaObject.media_object.media_id,
          mediaObjectType: mediaObject.media_object.media_type,
          reviewerSubmissionId: this.props.reviewerSubmission?.id,
        },
      })

      this.setState(
        {
          commentText: '',
          mediaObject: null,
          currentFiles: [],
          uploadingComments: false,
        },
        () => {
          if (this._commentTextBox) {
            this._commentTextBox.focus()
          }
        }
      )
      this.props.onSendCommentSuccess?.()
    })
  }

  onTextChange = e => {
    this.setState({commentText: e.target.value})
  }

  insertEmoji = emoji => {
    this.setState(
      state => {
        return {commentText: state.commentText + emoji.native}
      },
      () => {
        if (this._commentTextBox) {
          this._commentTextBox.focus()
        }
      }
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
        currentFiles: prevState.currentFiles.filter((_, i) => i !== fileIndex),
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

  handleMediaUpload = (error, uploadData, createSubmissionComment) => {
    if (error) {
      const errorMessage =
        error.file?.size > error.maxFileSize * 1024 * 1024
          ? I18n.t('File size exceeds the maximum of %{max} MB', {max: error.maxFileSize})
          : UploadMediaStrings.UPLOADING_ERROR

      this.context.setOnFailure(errorMessage)
    } else {
      this.setState({mediaObject: uploadData.mediaObject}, () => {
        this.onSendComment(createSubmissionComment)
      })
    }
  }

  render() {
    return (
      <Mutation
        onCompleted={result =>
          result.createSubmissionComment.errors
            ? this.context.setOnFailure(I18n.t('Error sending submission comment'))
            : this.context.setOnSuccess(I18n.t('Submission comment sent'))
        }
        onError={() => this.context.setOnFailure(I18n.t('Error sending submission comment'))}
        optimisticResponse={this.optimisticResponse()}
        update={this.updateSubmissionCommentCache}
        mutation={CREATE_SUBMISSION_COMMENT}
      >
        {createSubmissionComment => (
          <div>
            <div id="textarea-emoji-container">
              <TextArea
                label={<ScreenReaderContent>{I18n.t('Comment input box')}</ScreenReaderContent>}
                onChange={this.onTextChange}
                placeholder={I18n.t('Submit a Comment')}
                ref={el => {
                  this._commentTextBox = el
                }}
                value={this.state.commentText}
              />
              <span className="emoji-picker-container">
                {!this.state.uploadingComments && !!ENV.EMOJIS_ENABLED && (
                  <EmojiPicker insertEmoji={this.insertEmoji} />
                )}
              </span>
            </div>
            {this.state.uploadingComments && <LoadingIndicator />}
            {this.state.currentFiles.length !== 0 && !this.state.uploadingComments && (
              <div data-testid="assignments_2_comment_attachment">
                <FileList
                  files={this.state.currentFiles}
                  removeFileHandler={this.handleRemoveFile}
                  canRemove={true}
                />
              </div>
            )}
            {!this.state.uploadingComments && !this.state.hasError && (
              <div className="textarea-action-button-container">
                <span className="emoji-quick-picker-container">
                  {!!ENV.EMOJIS_ENABLED && <EmojiQuickPicker insertEmoji={this.insertEmoji} />}
                </span>
                <span className="textarea-action-buttons">
                  <input
                    id="attachmentFile"
                    ref={element => {
                      this.fileInput = element
                    }}
                    multiple={true}
                    onChange={this.onFileSelected}
                    style={{
                      display: 'none',
                    }}
                    type="file"
                  />
                  <IconButton
                    id="attachmentFileButton"
                    renderIcon={DEFAULT_ICON}
                    margin="0 x-small 0 0"
                    onClick={() => {
                      this.fileInput.click()
                    }}
                    ref={element => {
                      this.attachmentFileButton = element
                    }}
                    size="small"
                    screenReaderLabel={I18n.t('Attach a File')}
                    withBackground={false}
                    withBorder={false}
                  />
                  <IconButton
                    id="mediaCommentButton"
                    onClick={() => this.setState({mediaModalOpen: true})}
                    renderIcon={IconAttachMediaLine}
                    margin="0 x-small 0 0"
                    size="small"
                    disabled={this.state.mediaObject}
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel={I18n.t('Record Audio/Video')}
                  />
                  <UploadMedia
                    contextId={this.props.assignment.env.courseId}
                    contextType="course"
                    liveRegion={() => document.getElementById('flash_screenreader_holder')}
                    onDismiss={this.onMediaModalDismiss}
                    onUploadComplete={(error, data) => {
                      this.handleMediaUpload(error, data, createSubmissionComment)
                    }}
                    open={this.state.mediaModalOpen}
                    rcsConfig={{
                      contextId: this.props.assignment.env.courseId,
                      contextType: 'course',
                    }}
                    tabs={{embed: false, record: true, upload: true}}
                    uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings}}
                    userLocale={ENV.LOCALE}
                    disableSubmitWhileUploading={true}
                  />
                  <Button
                    disabled={
                      this.state.commentText.length === 0 && this.state.currentFiles.length === 0
                    }
                    onClick={() => this.onSendComment(createSubmissionComment)}
                  >
                    {I18n.t('Send Comment')}
                  </Button>
                </span>
              </div>
            )}
          </div>
        )}
      </Mutation>
    )
  }
}

CommentTextArea.contextType = AlertManagerContext
