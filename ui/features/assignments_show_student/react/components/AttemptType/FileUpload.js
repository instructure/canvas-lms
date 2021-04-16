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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {chunk} from 'lodash'
import {DEFAULT_ICON} from '@canvas/mime/react/mimeClassIconHelper'
import elideString from '../../helpers/elideString'
import {func} from 'prop-types'
import {getFileThumbnail} from '@canvas/util/fileHelper'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from '@canvas/loading-indicator'
import MoreOptions from './MoreOptions/index'
import React, {Component} from 'react'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {uploadFiles} from '@canvas/upload-file'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-file-drop'
import {Grid} from '@instructure/ui-grid'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'

function submissionFileUploadUrl(assignment) {
  return `/api/v1/courses/${assignment.env.courseId}/assignments/${assignment._id}/submissions/${assignment.env.currentUser.id}/files`
}

export default class FileUpload extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    createSubmissionDraft: func,
    submission: Submission.shape,
    updateUploadingFiles: func
  }

  state = {
    filesToUpload: [],
    messages: []
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    window.addEventListener('message', this.handleLTIFiles)
  }

  componentWillUnmount() {
    this._isMounted = false
    window.removeEventListener('message', this.handleLTIFiles)
  }

  getDraftAttachments = () => {
    return this.props.submission.submissionDraft &&
      this.props.submission.submissionDraft.attachments
      ? this.props.submission.submissionDraft.attachments
      : []
  }

  handleLTIFiles = async e => {
    if (e.data.messageType === 'LtiDeepLinkingResponse') {
      if (e.data.errormsg) {
        this.context.setOnFailure(e.data.errormsg)
        return
      }
      await this.handleDropAccepted(e.data.content_items)
    }

    // Since LTI 1.0 handles its own message alerting we don't have to
    if (e.data.messageType === 'A2ExternalContentReady') {
      if (!e.data.errormsg) {
        // Content type will be set on back-end to allow for DocViewer rendering
        const files = e.data.content_items.map(file => ({...file, mediaType: ''}))
        await this.handleDropAccepted(files)
      }
    }
  }

  handleCanvasFiles = async fileID => {
    if (!fileID) {
      this.context.setOnFailure(I18n.t('Error adding canvas file to submission draft'))
      return
    }
    this.updateUploadingFiles(async () => {
      try {
        await this.createSubmissionDraft([fileID])
      } catch (err) {
        this.context.setOnFailure(I18n.t('Error updating submission draft'))
      }
    })
  }

  handleDropAccepted = async files => {
    if (!files.length) {
      this.context.setOnFailure(I18n.t('Error adding files to submission draft'))
      return
    }

    this.setState(
      {
        filesToUpload: files.map((file, i) => {
          if (file.url) {
            return {isLoading: true, _id: `${i}-${file.url}`}
          }
          return {isLoading: true, _id: `${i}-${file.name}`}
        })
      },
      () => {
        this.context.setOnSuccess(I18n.t('Uploading files'))
      }
    )
    this.updateUploadingFiles(async () => {
      try {
        const newFiles = await uploadFiles(files, submissionFileUploadUrl(this.props.assignment))
        await this.createSubmissionDraft(newFiles.map(file => file.id))
      } catch (err) {
        this.context.setOnFailure(I18n.t('Error updating submission draft'))
      } finally {
        this.setState({filesToUpload: []})
      }
    })
  }

  handleDropRejected = () => {
    this.setState({
      messages: [
        {
          text: I18n.t('Invalid file type'),
          type: 'error'
        }
      ]
    })
  }

  updateUploadingFiles = async wrappedFunc => {
    if (this._isMounted) {
      this.props.updateUploadingFiles(true)
    }
    await wrappedFunc()
    if (this._isMounted) {
      this.props.updateUploadingFiles(false)
    }
  }

  createSubmissionDraft = async fileIDs => {
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_upload',
        attempt: this.props.submission.attempt || 1,
        fileIds: this.getDraftAttachments()
          .map(file => file._id)
          .concat(fileIDs)
      }
    })
  }

  handleRemoveFile = async e => {
    const fileId = parseInt(e.currentTarget.id, 10)
    const fileIndex = this.getDraftAttachments().findIndex(
      file => parseInt(file._id, 10) === fileId
    )

    const updatedFiles = this.getDraftAttachments().filter((_, i) => i !== fileIndex)
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_upload',
        attempt: this.props.submission.attempt,
        fileIds: updatedFiles.map(file => file._id)
      }
    })

    if (this._isMounted) {
      this.setState({
        messages: []
      })
    }

    const focusElement =
      this.getDraftAttachments().length === 0 || fileIndex === 0
        ? 'inputFileDrop'
        : this.getDraftAttachments()[fileIndex - 1]._id

    // TODO: this could break if there is ever another element in the dom that
    //       shares an id. As we are using _id (ie, '4') as the id, it's not
    //       exactly a great unique id. Should probably swap to using refs here.
    document.getElementById(focusElement).focus()
  }

  renderUploadBox() {
    return (
      <div data-testid="upload-box">
        <Flex direction="column">
          <Flex.Item margin="0 0 small 0" overflowY="visible">
            <FileDrop
              accept={
                this.props.assignment.allowedExtensions.length
                  ? this.props.assignment.allowedExtensions
                  : ''
              }
              allowMultiple
              enablePreview
              id="inputFileDrop"
              data-testid="input-file-drop"
              label={
                <Billboard
                  heading={I18n.t('Upload File')}
                  hero={DEFAULT_ICON}
                  message={
                    <Flex direction="column">
                      {this.props.assignment.allowedExtensions.length ? (
                        <Flex.Item>
                          {I18n.t('File permitted: %{fileTypes}', {
                            fileTypes: this.props.assignment.allowedExtensions
                              .map(ext => ext.toUpperCase())
                              .join(', ')
                          })}
                        </Flex.Item>
                      ) : null}
                      <Flex.Item padding="small 0 0">
                        <Text size="small">
                          {I18n.t('Drag and drop, or click to browse your computer')}
                        </Text>
                      </Flex.Item>
                    </Flex>
                  }
                />
              }
              messages={this.state.messages}
              onDropAccepted={files => this.handleDropAccepted(files)}
              onDropRejected={this.handleDropRejected}
            />
          </Flex.Item>
          <Flex.Item padding="xx-small" textAlign="center">
            <MoreOptions
              assignmentID={this.props.assignment._id}
              courseID={this.props.assignment.env.courseId}
              handleCanvasFiles={this.handleCanvasFiles}
              renderCanvasFiles
              userID={this.props.assignment.env.currentUser.id}
            />
          </Flex.Item>
        </Flex>
      </div>
    )
  }

  renderUploadedFile(file) {
    if (file.isLoading) {
      return <LoadingIndicator />
    }
    return (
      <Billboard
        heading={I18n.t('Uploaded')}
        headingLevel="h3"
        hero={getFileThumbnail(file, 'large')}
        message={
          <div>
            <span aria-hidden title={file.displayName}>
              {elideString(file.displayName)}
            </span>
            <ScreenReaderContent>{file.displayName}</ScreenReaderContent>
            <Button
              icon={IconTrashLine}
              id={file._id}
              margin="0 0 0 x-small"
              onClick={this.handleRemoveFile}
              size="small"
            >
              <ScreenReaderContent>
                {I18n.t('Remove %{filename}', {filename: file.displayName})}
              </ScreenReaderContent>
            </Button>
          </div>
        }
      />
    )
  }

  renderUploadBoxAndUploadedFiles() {
    let files = this.getDraftAttachments()
    if (this.state.filesToUpload.length) {
      files = files.concat(this.state.filesToUpload)
    }
    // The first two uploaded files are rendered on the same row as the upload box
    const firstFileRow = files.slice(0, 2)
    // All uploaded files after the first two are rendered on rows below the upload
    // box; thus, each row has three columns, with the first row having an upload box
    // and two rendered files and all subsequent rows having three rendered files
    const nextFileRows = files.length > 2 ? chunk(files.slice(2, files.length), 3) : []
    return (
      <Grid>
        <Grid.Row key="upload-box">
          <Grid.Col width={4}>{this.renderUploadBox()}</Grid.Col>
          {firstFileRow.map(file => (
            <Grid.Col width={4} key={file._id} vAlign="bottom">
              {this.renderUploadedFile(file)}
            </Grid.Col>
          ))}
        </Grid.Row>
        {nextFileRows.map((row, i) => (
          // eslint-disable-next-line react/no-array-index-key
          <Grid.Row key={i}>
            {row.map(file => (
              <Grid.Col width={4} key={file._id} vAlign="bottom">
                {this.renderUploadedFile(file)}
              </Grid.Col>
            ))}
          </Grid.Row>
        ))}
      </Grid>
    )
  }

  shouldRenderFiles = () => {
    return this.getDraftAttachments().length !== 0 || this.state.filesToUpload.length !== 0
  }

  render() {
    return (
      <div data-testid="upload-pane" style={{marginBottom: theme.variables.spacing.xxLarge}}>
        {this.renderUploadBoxAndUploadedFiles()}
      </div>
    )
  }
}

FileUpload.contextType = AlertManagerContext
