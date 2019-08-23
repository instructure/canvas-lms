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

import {Assignment} from '../../graphqlData/Assignment'
import {bool, func} from 'prop-types'
import {chunk} from 'lodash'
import {DEFAULT_ICON, getIconByType} from '../../../../shared/helpers/mimeClassIconHelper'
import elideString from '../../../../shared/helpers/elideString'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from '../../../shared/LoadingIndicator'
import MoreOptions from './MoreOptions'
import React, {Component} from 'react'
import {Submission} from '../../graphqlData/Submission'
import {uploadFiles} from '../../../../shared/upload_file'

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import Button from '@instructure/ui-buttons/lib/components/Button'
import FileDrop from '@instructure/ui-forms/lib/components/FileDrop'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'

function submissionFileUploadUrl(assignment) {
  return `/api/v1/courses/${assignment.env.courseId}/assignments/${assignment._id}/submissions/${assignment.env.currentUser.id}/files`
}

export default class FileUpload extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    createSubmissionDraft: func,
    submission: Submission.shape,
    updateUploadingFiles: func,
    uploadingFiles: bool
  }

  state = {
    messages: []
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    window.addEventListener('message', this.handleLTIFiles)
  }

  componentWillUnmount() {
    this._isMounted = false
  }

  getDraftAttachments = () => {
    return this.props.submission.submissionDraft &&
      this.props.submission.submissionDraft.attachments
      ? this.props.submission.submissionDraft.attachments
      : []
  }

  handleLTIFiles = async e => {
    if (e.data.messageType === 'LtiDeepLinkingResponse') {
      await this.handleDropAccepted(e.data.content_items)
    }
  }

  handleDropAccepted = async files => {
    if (this._isMounted) {
      this.props.updateUploadingFiles(true)
    }

    if (files.length) {
      const newFiles = await uploadFiles(files, submissionFileUploadUrl(this.props.assignment))

      await this.props.createSubmissionDraft({
        variables: {
          id: this.props.submission.id,
          attempt: this.props.submission.attempt || 1,
          fileIds: this.getDraftAttachments()
            .map(file => file._id)
            .concat(newFiles.map(file => file.id))
        }
      })
    }

    if (this._isMounted) {
      this.props.updateUploadingFiles(false)
    }
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

  handleRemoveFile = async e => {
    e.preventDefault()
    const fileId = parseInt(e.currentTarget.id, 10)
    const fileIndex = this.getDraftAttachments().findIndex(
      file => parseInt(file._id, 10) === fileId
    )

    const updatedFiles = this.getDraftAttachments().filter((_, i) => i !== fileIndex)
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        attempt: this.props.submission.attempt,
        fileIds: updatedFiles.map(file => file._id)
      }
    })

    this.setState({
      messages: []
    })

    const focusElement =
      this.getDraftAttachments().length === 0 || fileIndex === 0
        ? 'inputFileDrop'
        : this.getDraftAttachments()[fileIndex - 1]._id

    // TODO: this could break if there is ever another element in the dom that
    //       shares an id. As we are using _id (ie, '4') as the id, it's not
    //       exactly a great unique id. Should probably swap to using refs here.
    document.getElementById(focusElement).focus()
  }

  shouldDisplayThumbnail = file => {
    return file.mimeClass === 'image' && file.thumbnailUrl
  }

  renderUploadBox() {
    return (
      <div data-testid="upload-box">
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
                    <FlexItem>
                      {I18n.t('File permitted: %{fileTypes}', {
                        fileTypes: this.props.assignment.allowedExtensions
                          .map(ext => ext.toUpperCase())
                          .join(', ')
                      })}
                    </FlexItem>
                  ) : null}
                  <FlexItem padding="small 0 0">
                    <Text size="small">
                      {I18n.t('Drag and drop, or click to browse your computer')}
                    </Text>
                    <MoreOptions
                      assignmentID={this.props.assignment._id}
                      courseID={this.props.assignment.env.courseId}
                      userID={this.props.assignment.env.currentUser.id}
                    />
                  </FlexItem>
                </Flex>
              }
            />
          }
          messages={this.state.messages}
          onDropAccepted={this.handleDropAccepted}
          onDropRejected={this.handleDropRejected}
        />
      </div>
    )
  }

  renderUploadedFile(file) {
    return (
      <Billboard
        heading={I18n.t('Uploaded')}
        headingLevel="h3"
        hero={
          this.shouldDisplayThumbnail(file) ? (
            <img
              alt={I18n.t('%{filename} preview', {filename: file.displayName})}
              height="75"
              src={file.thumbnailUrl}
              width="75"
            />
          ) : (
            getIconByType(file.mimeClass)
          )
        }
        message={
          <div>
            <span aria-hidden title={file.displayName}>
              {elideString(file.displayName)}
            </span>
            <ScreenReaderContent>{file.displayName}</ScreenReaderContent>
            <Button
              icon={IconTrash}
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
    const files = this.getDraftAttachments()
    // The first two uploaded files are rendered on the same row as the upload box
    const firstFileRow = files.slice(0, 2)
    // All uploaded files after the first two are rendered on rows below the upload
    // box; thus, each row has three columns, with the first row having an upload box
    // and two rendered files and all subsequent rows having three rendered files
    const nextFileRows = files.length > 2 ? chunk(files.slice(2, files.length), 3) : []
    return (
      <div data-testid="non-empty-upload">
        <Grid>
          <GridRow key={firstFileRow.map(file => file._id).join()}>
            <GridCol width={4}>{this.renderUploadBox()}</GridCol>
            {firstFileRow.map(file => (
              <GridCol width={4} key={file._id} vAlign="bottom">
                {this.renderUploadedFile(file)}
              </GridCol>
            ))}
          </GridRow>
          {nextFileRows.map(row => (
            <GridRow key={row.map(file => file._id).join()}>
              {row.map(file => (
                <GridCol width={4} key={file._id} vAlign="bottom">
                  {this.renderUploadedFile(file)}
                </GridCol>
              ))}
            </GridRow>
          ))}
        </Grid>
      </div>
    )
  }

  render() {
    return (
      <div data-testid="upload-pane">
        {this.getDraftAttachments().length !== 0 ? (
          this.renderUploadBoxAndUploadedFiles()
        ) : (
          <Grid>
            <GridRow>
              <GridCol width={4}>{this.renderUploadBox()}</GridCol>
            </GridRow>
          </Grid>
        )}

        {this.props.uploadingFiles && <LoadingIndicator />}
      </div>
    )
  }
}
