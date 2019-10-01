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
import {arrayOf, bool, func, shape, string} from 'prop-types'
import React, {Suspense} from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import {Tabs} from '@instructure/ui-tabs'

import {ACCEPTED_FILE_TYPES} from './acceptedMediaFileTypes'
import LoadingIndicator from './shared/LoadingIndicator'
import saveMediaRecording, {saveClosedCaptions} from './saveMediaRecording'
import translationShape from './translationShape'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const EmbedPanel = React.lazy(() => import('./EmbedPanel'))
const MediaRecorder = React.lazy(() => import('./MediaRecorder'))

export const PANELS = {
  COMPUTER: 0,
  RECORD: 1,
  EMBED: 2,
  CLOSED_CAPTIONS: 3
}

export default class UploadMedia extends React.Component {
  static propTypes = {
    languages: arrayOf(
      shape({
        id: string,
        label: string
      })
    ),
    liveRegion: func,
    contextId: string,
    contextType: string,
    onStartUpload: func,
    onUploadComplete: func,
    onEmbed: func,
    onDismiss: func,
    open: bool,
    tabs: shape({
      embed: bool,
      record: bool,
      upload: bool
    }),
    uploadMediaTranslations: translationShape
  }

  state = {
    embedCode: '',
    hasUploadedFile: false,
    selectedPanel: 0,
    theFile: null
  }

  constructor() {
    super()
    this.subtitles = []
  }

  handleSubmit = () => {
    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER:
      case PANELS.RECORD: {
        this.props.onStartUpload && this.props.onStartUpload(this.state.theFile)
        saveMediaRecording(
          this.state.theFile,
          this.props.contextId,
          this.props.contextType,
          this.saveMediaCallback
        )
        break
      }
      case PANELS.EMBED: {
        this.props.onDismiss()
        this.props.onEmbed(this.state.embedCode)
        break
      }
      default:
        throw new Error('Selected Panel is invalid') // Should never get here
    }
  }

  saveMediaCallback = async (err, data) => {
    if (err) {
      // handle error
    } else {
      try {
        if (this.subtitles.length > 0) {
          await saveClosedCaptions(data.mediaObject.media_object.media_id, this.subtitles)
        }
        this.props.onDismiss && this.props.onDismiss()
        this.props.onUploadComplete && this.props.onUploadComplete(null, data)
      } catch (ex) {
        // Handle error
        console.error(ex) // eslint-disable-line no-console
      }
    }
  }

  renderModalBody = () => {
    const {
      COMPUTER_PANEL_TITLE,
      DRAG_FILE_TEXT,
      EMBED_PANEL_TITLE,
      EMBED_VIDEO_CODE_TEXT,
      LOADING_MEDIA,
      RECORD_PANEL_TITLE,
      MEDIA_RECORD_NOT_AVAILABLE
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <Tabs
        shouldFocusOnRender
        maxWidth="large"
        onRequestTabChange={(_, {index}) => {
          this.subtitles = []
          this.setState({selectedPanel: index})
        }}
      >
        {this.props.tabs.upload && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.COMPUTER}
            renderTitle={() => COMPUTER_PANEL_TITLE}
          >
            <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
              <ComputerPanel
                theFile={this.state.theFile}
                setFile={file => this.setState({theFile: file})}
                hasUploadedFile={this.state.hasUploadedFile}
                setHasUploadedFile={uploadFileState =>
                  this.setState({hasUploadedFile: uploadFileState})
                }
                label={DRAG_FILE_TEXT}
                uploadMediaTranslations={this.props.uploadMediaTranslations}
                accept={ACCEPTED_FILE_TYPES}
                languages={this.props.languages}
                liveRegion={this.props.liveRegion}
                updateSubtitles={subtitles => (this.subtitles = subtitles)}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.record && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.RECORD}
            renderTitle={() => RECORD_PANEL_TITLE}
          >
            <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
              <MediaRecorder
                MediaCaptureStrings={this.props.uploadMediaTranslations.MediaCaptureStrings}
                errorMessage={MEDIA_RECORD_NOT_AVAILABLE}
                onSave={file => this.setState({theFile: file}, this.handleSubmit)}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.embed && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.EMBED}
            renderTitle={() => EMBED_PANEL_TITLE}
          >
            <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
              <EmbedPanel
                label={EMBED_VIDEO_CODE_TEXT}
                embedCode={this.state.embedCode}
                setEmbedCode={embedCode => this.setState({embedCode})}
              />
            </Suspense>
          </Tabs.Panel>
        )}
      </Tabs>
    )
  }

  onModalClose = () => {
    this.setState({
      embedCode: '',
      hasUploadedFile: false,
      selectedPanel: 0,
      theFile: null
    })
    this.props.onDismiss()
  }

  renderModalFooter = () => {
    if (this.state.selectedPanel === PANELS.RECORD) {
      return null
    }

    const {CLOSE_TEXT, SUBMIT_TEXT} = this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <Modal.Footer>
        <Button onClick={this.onModalClose}> {CLOSE_TEXT} </Button>
        &nbsp;
        <Button
          onClick={e => {
            e.preventDefault()
            this.handleSubmit()
          }}
          variant="primary"
          type="submit"
        >
          {SUBMIT_TEXT}
        </Button>
      </Modal.Footer>
    )
  }

  render() {
    const {CLOSE_TEXT, UPLOAD_MEDIA_LABEL} = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <Modal
        label={UPLOAD_MEDIA_LABEL}
        size="large"
        onDismiss={this.onModalClose}
        open={this.props.open}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton onClick={this.onModalClose} offset="medium" placement="end">
            {CLOSE_TEXT}
          </CloseButton>
          <Heading>{UPLOAD_MEDIA_LABEL}</Heading>
        </Modal.Header>
        <Modal.Body>{this.renderModalBody()}</Modal.Body>
        {this.renderModalFooter()}
      </Modal>
    )
  }
}
