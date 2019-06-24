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

import {AssignmentShape, SubmissionShape} from '../assignmentData'
import {chunk} from 'lodash'
import {DEFAULT_ICON, getIconByType} from '../../../shared/helpers/mimeClassIconHelper'
import {func} from 'prop-types'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {Component} from 'react'
import {uploadFiles} from '../../../shared/upload_file'

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import Button from '@instructure/ui-buttons/lib/components/Button'
import FileDrop from '@instructure/ui-forms/lib/components/FileDrop'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import theme from '@instructure/ui-themes/lib/canvas/base'

function submissionFileUploadUrl(assignment) {
  return `/api/v1/courses/${assignment.env.courseId}/assignments/${assignment._id}/submissions/${
    assignment.env.currentUser.id
  }/files`
}

export default class FileUpload extends Component {
  static propTypes = {
    assignment: AssignmentShape,
    createSubmission: func,
    createSubmissionDraft: func,
    submission: SubmissionShape,
    updateSubmissionState: func,
    updateUploadState: func
  }

  state = {
    messages: [],
    uploadingFiles: false
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
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

  handleDropAccepted = async files => {
    if (this._isMounted) {
      this.setState({uploadingFiles: true})
    }

    if (files.length) {
      try {
        const newFiles = await uploadFiles(files, submissionFileUploadUrl(this.props.assignment))

        await this.props.createSubmissionDraft({
          variables: {
            id: this.props.submission.id,
            attempt: this.props.submission.attempt,
            fileIds: this.getDraftAttachments()
              .map(file => file._id)
              .concat(newFiles.map(file => file.id))
          }
        })
      } catch (err) {
        if (this._isMounted) {
          this.props.updateUploadState('error')
        }
      }
    }

    if (this._isMounted) {
      this.setState({uploadingFiles: false})
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

  ellideString = title => {
    if (title.length > 21) {
      return `${title.substr(0, 9)}${I18n.t('...')}${title.substr(-9)}`
    } else {
      return title
    }
  }

  submitAssignment = async () => {
    if (this._isMounted) {
      this.props.updateSubmissionState('in-progress')
    }

    await this.props.createSubmission({
      variables: {
        assignmentLid: this.props.assignment._id,
        submissionID: this.props.submission.id,
        type: 'online_upload', // TODO: update to enable different submission types
        fileIds: this.getDraftAttachments().map(file => file._id)
      }
    })

    if (this._isMounted) {
      this.setState({messages: []})
    }
  }

  renderEmptyUpload() {
    return (
      <div data-testid="empty-upload">
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
              </FlexItem>
            </Flex>
          }
        />
      </div>
    )
  }

  renderLoadingIndicator() {
    return (
      <GridRow>
        <GridCol>
          <LoadingIndicator />
        </GridCol>
      </GridRow>
    )
  }

  renderUploadedFiles() {
    const fileRows = chunk(this.getDraftAttachments(), 3)
    return (
      <div data-testid="non-empty-upload">
        <Grid>
          {fileRows.map(row => (
            <GridRow key={row.map(file => file._id).join()}>
              {row.map(file => (
                <GridCol key={file._id} vAlign="bottom">
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
                          {this.ellideString(file.displayName)}
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
                </GridCol>
              ))}
            </GridRow>
          ))}
          {this.state.uploadingFiles && this.renderLoadingIndicator()}
        </Grid>
      </div>
    )
  }

  renderSubmitButton = () => {
    const outerFooterStyle = {
      position: 'fixed',
      bottom: '0',
      left: '0',
      right: '0',
      maxWidth: '1366px',
      margin: '0 0 0 84px',
      zIndex: '5'
    }

    // TODO: Delete this once the better global footers are implemented. This
    //       is some pretty ghetto stuff to handle the fixed buttom bars (for
    //       masquarading and beta instances) that would otherwise hide the
    //       submit button.
    let paddingOffset = 0
    if (document.getElementById('masquerade_bar')) {
      paddingOffset += 52
    }
    if (document.getElementById('element_toggler_0')) {
      paddingOffset += 63
    }

    const innerFooterStyle = {
      backgroundColor: theme.variables.colors.white,
      borderColor: theme.variables.colors.borderMedium,
      borderTop: `1px solid ${theme.variables.colors.borderMedium}`,
      textAlign: 'right',
      margin: `0 ${theme.variables.spacing.medium}`,
      paddingBottom: `${paddingOffset}px`
    }

    return (
      <div style={outerFooterStyle}>
        <div style={innerFooterStyle}>
          <Button
            id="submit-button"
            data-testid="submit-button"
            variant="primary"
            margin="xx-small 0"
            onClick={() => this.submitAssignment()}
          >
            {I18n.t('Submit')}
          </Button>
        </div>
      </div>
    )
  }

  renderUploadBox() {
    return (
      <FileDrop
        accept={
          this.props.assignment.allowedExtensions.length
            ? this.props.assignment.allowedExtensions
            : ''
        }
        allowMultiple
        enablePreview
        id="inputFileDrop"
        data-testid="inputFileDrop"
        label={
          this.getDraftAttachments().length || this.state.uploadingFiles
            ? this.renderUploadedFiles()
            : this.renderEmptyUpload()
        }
        messages={this.state.messages}
        onDropAccepted={this.handleDropAccepted}
        onDropRejected={this.handleDropRejected}
      />
    )
  }

  render() {
    return (
      <React.Fragment>
        {this.state.uploadingFiles ? this.renderUploadedFiles() : this.renderUploadBox()}
        {this.getDraftAttachments().length !== 0 &&
          !this.state.uploadingFiles &&
          this.renderSubmitButton()}
      </React.Fragment>
    )
  }
}
