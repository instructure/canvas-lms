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

import {bool, func} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import React, {Suspense} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-layout'

import {ACCEPTED_FILE_TYPES} from './acceptedMediaFileTypes'
import translationShape from './translationShape'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const EmbedPanel = React.lazy(() => import('./EmbedPanel'))
const MediaRecorder = React.lazy(() => import('./MediaRecorder'))

export const PANELS = {
  COMPUTER: 0,
  RECORD: 1,
  EMBED: 2
}

export const handleSubmit = (editor, selectedPanel, uploadData, saveMediaRecording, onDismiss) => {
  switch (selectedPanel) {
    case PANELS.COMPUTER: {
      const {theFile} = uploadData
      saveMediaRecording(theFile, editor, onDismiss)
      break;
    }
    case PANELS.EMBED: {
      const {embedCode} = uploadData
      editor.insertContent(embedCode)
      onDismiss()
      break
    }
    default:
      throw new Error('Selected Panel is invalid') // Should never get here
  }
}

export default class UploadMedia extends React.Component {

  static propTypes = {
    onDismiss: func,
    open: bool,
    uploadMediaTranslations: translationShape
  }

  state = {
    theFile: null,
    hasUploadedFile: false,
    selectedPanel: 0,
    embedCode: ''
  }


  renderModalBody = () => {
    return (
      <Tabs shouldFocusOnRender maxWidth="large" onRequestTabChange={(_, { index }) => this.setState({selectedPanel: index})}>
        <Tabs.Panel isSelected={this.state.selectedPanel === PANELS.COMPUTER} renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.COMPUTER_PANEL_TITLE}>
          <Suspense fallback={
            <View as="div" height="100%" width="100%" textAlign="center">
              <Spinner renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.LOADING_MEDIA}  size="large" margin="0 0 0 medium" />
            </View>
          } size="large">
            <ComputerPanel
              theFile={this.state.theFile}
              setFile={(file) => this.setState({theFile: file})}
              hasUploadedFile={this.state.hasUploadedFile}
              setHasUploadedFile={(uploadFileState) => this.setState({hasUploadedFile: uploadFileState})}
              label={this.props.uploadMediaTranslations.UploadMediaStrings.DRAG_FILE_TEXT}
              uploadMediaTranslations={this.props.uploadMediaTranslations}
              accept={ACCEPTED_FILE_TYPES}
            />
          </Suspense>
        </Tabs.Panel>
        <Tabs.Panel isSelected={this.state.selectedPanel === PANELS.RECORD} renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.RECORD_PANEL_TITLE}>
          <Suspense fallback={
            <View as="div" height="100%" width="100%" textAlign="center">
              <Spinner renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.LOADING_MEDIA} size="large" margin="0 0 0 medium" />
            </View>
          }>
          <MediaRecorder
            MediaCaptureStrings={this.props.uploadMediaTranslations.MediaCaptureStrings}
            errorMessage={this.props.uploadMediaTranslations.UploadMediaStrings.UPLOADING_ERROR} dismiss={this.props.onDismiss}/>
          </Suspense>
        </Tabs.Panel>
        <Tabs.Panel isSelected={this.state.selectedPanel === PANELS.EMBED} renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.EMBED_PANEL_TITLE}>
          <Suspense fallback={
            <View as="div" height="100%" width="100%" textAlign="center">
              <Spinner renderTitle={() => this.props.uploadMediaTranslations.UploadMediaStrings.LOADING_MEDIA}  size="large" margin="0 0 0 medium" />
            </View>
          }>
          <EmbedPanel
            label={this.props.uploadMediaTranslations.UploadMediaStrings.EMBED_VIDEO_CODE_TEXT}
            embedCode={this.state.embedCode}
            setEmbedCode={(embedCode) => this.setState({embedCode})} />
          </Suspense>
        </Tabs.Panel>
      </Tabs>
    )
  }

  renderModalFooter = () => {
    if (this.state.selectedPanel !== PANELS.RECORD) {
      return (
        <Modal.Footer>
          <Button onClick={this.props.onDismiss}>
            {this.props.uploadMediaTranslations.UploadMediaStrings.CLOSE_TEXT}
          </Button>&nbsp;
          <Button
            onClick={e => {
              e.preventDefault()
              handleSubmit()
            }}
            variant="primary"
            type="submit">
            {this.props.uploadMediaTranslations.UploadMediaStrings.SUBMIT_TEXT}
          </Button>
        </Modal.Footer>
      )
    }
    return null
  }

  render() {
    return (
      <Modal
        label={this.props.uploadMediaTranslations.UploadMediaStrings.UPLOAD_MEDIA_LABEL}
        size="medium"
        onDismiss={this.props.onDismiss}
        open={this.props.open}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton onClick={this.props.onDismiss} offset="medium" placement="end">
            {this.props.uploadMediaTranslations.UploadMediaStrings.CLOSE_TEXT}
          </CloseButton>
          <Heading>{this.props.uploadMediaTranslations.UploadMediaStrings.UPLOAD_MEDIA_LABEL}</Heading>
        </Modal.Header>
        <Modal.Body>
          {this.renderModalBody()}
        </Modal.Body>
        {this.renderModalFooter()}
      </Modal>
    )
  }
}
