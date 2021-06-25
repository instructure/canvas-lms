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
import axios from '@canvas/axios'
import elideString from '../../helpers/elideString'
import {func} from 'prop-types'
import {getFileThumbnail} from '@canvas/util/fileHelper'
import I18n from 'i18n!assignments_2_file_upload'
import MoreOptions from './MoreOptions/index'
import React, {Component} from 'react'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {uploadFile} from '@canvas/upload-file'
import UploadFileSVG from '../../../images/UploadFile.svg'

import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconCompleteSolid, IconTrashLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {ProgressBar} from '@instructure/ui-progress'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
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
          const name = file.name || file.title || file.url
          const _id = `${i}-${file.url || file.name}`

          // As we receive progress events for this upload, we'll update the
          // "loaded and "total" values. Set some placeholder values so that
          // we start at 0%.
          return {_id, index: i, isLoading: true, name, loaded: 0, total: 1}
        })
      },
      () => {
        this.context.setOnSuccess(I18n.t('Uploading files'))
      }
    )
    this.updateUploadingFiles(async () => {
      try {
        const newFiles = await this.uploadFiles(files)
        await this.createSubmissionDraft(newFiles.map(file => file.id))
      } catch (err) {
        this.context.setOnFailure(I18n.t('Error updating submission draft'))
      } finally {
        this.setState({filesToUpload: []})
      }
    })
  }

  uploadFiles = async files => {
    // This is taken almost verbatim from the uploadFiles method in the
    // upload-file module.  Rather than calling that method, we call uploadFile
    // for each file to track progress for the individual uploads.
    const uploadUrl = submissionFileUploadUrl(this.props.assignment)

    const uploadPromises = []
    files.forEach((file, i) => {
      const onProgress = event => {
        const {loaded, total} = event
        this.updateUploadProgress({index: i, loaded, total})
      }

      let promise
      if (file.url) {
        promise = uploadFile(
          uploadUrl,
          {
            url: file.url,
            name: file.title,
            content_type: file.mediaType,
            submit_assignment: false
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
            content_type: file.type
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
    const fileDropLabel = (
      <>
        <ScreenReaderContent>
          {I18n.t('Drag a file here, or click to select a file to upload')}
        </ScreenReaderContent>
        <Flex justifyItems="center" margin="small">
          <Flex.Item>
            <Img src={UploadFileSVG} size="large" />
          </Flex.Item>
          <Flex.Item padding="0 0 0 small">
            <Flex direction="column" textAlign="start">
              <Flex.Item margin="0 0 small 0" overflowY="visible">
                <Text size="x-large">{I18n.t('Drag a file here, or')}</Text>
              </Flex.Item>
              <Flex.Item>
                <Text color="brand" size="medium">
                  {I18n.t('Choose a file to upload')}
                </Text>
              </Flex.Item>
              {this.props.assignment.allowedExtensions.length && (
                <Flex.Item>
                  {I18n.t('File permitted: %{fileTypes}', {
                    fileTypes: this.props.assignment.allowedExtensions
                      .map(ext => ext.toUpperCase())
                      .join(', ')
                  })}
                </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
        </Flex>
      </>
    )

    return (
      <div data-testid="upload-box">
        <Flex direction="column" padding="xx-small">
          <Flex.Item margin="0 0 small 0" overflowY="visible">
            <FileDrop
              accept={
                this.props.assignment.allowedExtensions.length
                  ? this.props.assignment.allowedExtensions
                  : ''
              }
              id="inputFileDrop"
              data-testid="input-file-drop"
              margin="xx-small"
              messages={this.state.messages}
              onDropAccepted={files => this.handleDropAccepted(files)}
              onDropRejected={this.handleDropRejected}
              renderLabel={fileDropLabel}
              shouldAllowMultiple
              shouldEnablePreview
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

  renderFileProgress = file => {
    // If we're calling this function, we know that "file" represents one of
    // the entries in the filesToUpload state variable, and so it will have
    // values representing the progress of the upload.
    const {name, loaded, total} = file

    return (
      <ProgressBar
        formatScreenReaderValue={({valueNow, valueMax}) => {
          return Math.round((valueNow / valueMax) * 100) + ' percent'
        }}
        meterColor="brand"
        screenReaderLabel={I18n.t('Upload progress for %{name}', {name})}
        size="x-small"
        valueMax={total}
        valueNow={loaded}
      />
    )
  }

  renderTableRow = file => {
    // "file" is either a previously-uploaded file or one being uploaded right
    // now.  For the former, we can use the displayName property; files being
    // uploaded don't have that set yet, so use the local name (which we've set
    // to the URL for files from an LTI).
    const displayName = file.displayName || file.name

    return (
      <Table.Row key={file._id}>
        <Table.Cell>{getFileThumbnail(file, 'small')}</Table.Cell>
        <Table.Cell>
          {displayName && (
            <>
              <span aria-hidden title={displayName}>
                {elideString(displayName)}
              </span>
              <ScreenReaderContent>{displayName}</ScreenReaderContent>
            </>
          )}
        </Table.Cell>
        <Table.Cell>{file.isLoading && this.renderFileProgress(file)}</Table.Cell>
        <Table.Cell>{!file.isLoading && <IconCompleteSolid color="success" />}</Table.Cell>
        <Table.Cell>
          {!file.isLoading && (
            <IconButton
              id={file._id}
              onClick={this.handleRemoveFile}
              screenReaderLabel={I18n.t('Remove %{displayName}', {displayName})}
              size="small"
              withBackground={false}
              withBorder={false}
            >
              <IconTrashLine />
            </IconButton>
          )}
        </Table.Cell>
      </Table.Row>
    )
  }

  renderUploadedFiles = files => {
    return (
      <Table caption={I18n.t('Uploaded files')} data-testid="uploaded_files_table">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="thumbnail" width="1rem" />
            <Table.ColHeader id="filename">{I18n.t('File Name')}</Table.ColHeader>
            <Table.ColHeader id="upload-progress" width="30%" />
            <Table.ColHeader id="upload-success" width="1rem" />
            <Table.ColHeader id="delete" width="1rem" />
          </Table.Row>
        </Table.Head>
        <Table.Body>{files.map(this.renderTableRow)}</Table.Body>
      </Table>
    )
  }

  render() {
    let files = this.getDraftAttachments()
    if (this.state.filesToUpload.length) {
      files = files.concat(this.state.filesToUpload)
    }

    return (
      <div data-testid="upload-pane" style={{marginBottom: theme.variables.spacing.xxLarge}}>
        <Flex direction="column" width="100%" alignItems="stretch">
          <Flex.Item>{this.renderUploadBox()}</Flex.Item>

          {files.length > 0 && <Flex.Item>{this.renderUploadedFiles(files)}</Flex.Item>}
        </Flex>
      </div>
    )
  }
}

FileUpload.contextType = AlertManagerContext
