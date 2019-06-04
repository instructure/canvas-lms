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

import AssignmentAlert from './AssignmentAlert'
import {
  AssignmentShape,
  CREATE_SUBMISSION,
  STUDENT_VIEW_QUERY,
  SubmissionShape
} from '../assignmentData'
import {chunk} from 'lodash'
import {DEFAULT_ICON, getIconByType} from '../../../shared/helpers/mimeClassIconHelper'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import mimeClass from 'compiled/util/mimeClass'
import {Mutation} from 'react-apollo'
import React, {Component} from 'react'
import {submissionFileUploadUrl, uploadFiles} from '../../../shared/upload_file'

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import Button from '@instructure/ui-buttons/lib/components/Button'
import FileDrop from '@instructure/ui-forms/lib/components/FileDrop'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import theme from '@instructure/ui-themes/lib/canvas/base'

export default class ContentUploadTab extends Component {
  static propTypes = {
    assignment: AssignmentShape,
    submission: SubmissionShape
  }

  loadDraftFiles = () => {
    if (this.props.submission.submissionDraft) {
      return this.props.submission.submissionDraft.attachments.map(attachment => ({
        id: attachment._id,
        mimeClass: attachment.mimeClass,
        name: attachment.displayName,
        preview: attachment.thumbnailUrl
      }))
    } else {
      return []
    }
  }

  state = {
    files: this.loadDraftFiles(),
    messages: [],
    submissionFailed: false,
    uploadingFiles: false
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
  }

  componentWillUnmount() {
    this._isMounted = false
  }

  handleDropAccepted = files => {
    // add a unique index with which to key off of
    let currIndex = this.state.files.length ? this.state.files[this.state.files.length - 1].id : 0
    files.map(file => (file.id = ++currIndex))

    this.setState(prevState => ({
      files: prevState.files.concat(files),
      messages: []
    }))
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

  handleRemoveFile = e => {
    e.preventDefault()
    const fileId = parseInt(e.currentTarget.id, 10)
    const fileIndex = this.state.files.findIndex(file => parseInt(file.id, 10) === fileId)

    this.setState(
      prevState => ({
        files: prevState.files.filter((_, i) => i !== fileIndex),
        messages: []
      }),
      () => {
        const focusElement =
          this.state.files.length === 0 || fileIndex === 0
            ? 'inputFileDrop'
            : this.state.files[fileIndex - 1].id
        document.getElementById(focusElement).focus()
      }
    )
  }

  shouldDisplayThumbnail = file => {
    return (file.mimeClass || mimeClass(file.type)) === 'image' && file.preview
  }

  ellideString = title => {
    if (title.length > 21) {
      return `${title.substr(0, 9)}${I18n.t('...')}${title.substr(-9)}`
    } else {
      return title
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

  renderUploadedFiles() {
    const fileRows = chunk(this.state.files, 3)
    return (
      <div data-testid="non-empty-upload">
        <Grid>
          {fileRows.map(row => (
            <GridRow key={row.map(file => file.id).join()}>
              {row.map(file => (
                <GridCol key={file.id} vAlign="bottom">
                  <Billboard
                    heading={I18n.t('Uploaded')}
                    headingLevel="h3"
                    hero={
                      this.shouldDisplayThumbnail(file) ? (
                        <img
                          alt={I18n.t('%{filename} preview', {filename: file.name})}
                          height="75"
                          src={file.preview}
                          width="75"
                        />
                      ) : (
                        getIconByType(mimeClass(file.type))
                      )
                    }
                    message={
                      <div>
                        <span aria-hidden title={file.name}>
                          {this.ellideString(file.name)}
                        </span>
                        <ScreenReaderContent>{file.name}</ScreenReaderContent>
                        <Button
                          icon={IconTrash}
                          id={file.id}
                          margin="0 0 0 x-small"
                          onClick={this.handleRemoveFile}
                          size="small"
                        >
                          <ScreenReaderContent>
                            {I18n.t('Remove %{filename}', {filename: file.name})}
                          </ScreenReaderContent>
                        </Button>
                      </div>
                    }
                  />
                </GridCol>
              ))}
            </GridRow>
          ))}
        </Grid>
      </div>
    )
  }

  updateAssignmentCache = (cache, submission) => {
    const {assignment} = cache.readQuery({
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: this.props.assignment._id
      }
    })

    assignment.submissionsConnection.nodes = assignment.submissionsConnection.nodes.concat([
      submission.data.createSubmission.submission
    ])

    cache.writeQuery({
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: this.props.assignment._id
      },
      data: {assignment}
    })
  }

  renderAlert = (data, error) => {
    if (error) {
      return (
        <AssignmentAlert
          errorMessage={I18n.t('Error sending submission')}
          onDismiss={() => this.setState({submissionFailed: false, uploadingFiles: false})}
        />
      )
    }
    if (data) {
      return <AssignmentAlert successMessage={I18n.t('Submission sent')} />
    }
  }

  submitAssignment = createSubmission => {
    this.setState({submissionFailed: false, uploadingFiles: true}, async () => {
      let fileIds = []

      if (this.state.files.length) {
        try {
          const attachments = await uploadFiles(
            this.state.files,
            submissionFileUploadUrl(this.props.assignment)
          )
          fileIds = attachments.map(attachment => attachment.id)
        } catch (err) {
          if (this._isMounted) {
            this.setState({submissionFailed: true, uploadingFiles: false})
          }
          return
        }
      }
      await createSubmission({
        variables: {
          id: this.props.assignment._id,
          type: 'online_upload', // TODO: update to enable different submission types
          fileIds
        }
      })

      if (this._isMounted) {
        this.setState({files: [], messages: [], uploadingFiles: false})
      }
    })
  }

  renderSubmitButton = createSubmission => {
    const outerFooterStyle = {
      position: 'fixed',
      bottom: '0',
      left: '0',
      right: '0',
      maxWidth: '1366px',
      margin: '0 0 0 84px',
      zIndex: '5'
    }

    const innerFooterStyle = {
      backgroundColor: theme.variables.colors.white,
      borderColor: theme.variables.colors.borderMedium,
      borderTop: `1px solid ${theme.variables.colors.borderMedium}`,
      textAlign: 'right',
      margin: `0 ${theme.variables.spacing.medium}`
    }

    return (
      <div style={outerFooterStyle}>
        <div style={innerFooterStyle}>
          <Button
            variant="primary"
            margin="xx-small 0"
            onClick={() => this.submitAssignment(createSubmission)}
          >
            {I18n.t('Submit')}
          </Button>
        </div>
      </div>
    )
  }

  render() {
    return (
      <Mutation mutation={CREATE_SUBMISSION} update={this.updateAssignmentCache}>
        {(createSubmission, {data, error}) => (
          <React.Fragment>
            {this.renderAlert(data, error || this.state.submissionFailed)}
            {/* TODO: replace loading indicator with a progress bar */}
            {this.state.uploadingFiles && !error && !this.state.submissionFailed && (
              <LoadingIndicator />
            )}
            {!this.state.uploadingFiles && !this.state.submissionFailed && (
              <React.Fragment>
                <FileDrop
                  accept={
                    this.props.assignment.allowedExtensions.length
                      ? this.props.assignment.allowedExtensions
                      : ''
                  }
                  allowMultiple
                  enablePreview
                  id="inputFileDrop"
                  label={
                    this.state.files.length ? this.renderUploadedFiles() : this.renderEmptyUpload()
                  }
                  messages={this.state.messages}
                  onDropAccepted={this.handleDropAccepted}
                  onDropRejected={this.handleDropRejected}
                />
                {this.state.files.length !== 0 && this.renderSubmitButton(createSubmission)}
              </React.Fragment>
            )}
          </React.Fragment>
        )}
      </Mutation>
    )
  }
}
