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
import {Heading, Spinner} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-layout'

import {ACCEPTED_FILE_TYPES} from './acceptedMediaFileTypes'
import saveMediaRecording from './saveMediaRecording'
import translationShape from './translationShape'

const ClosedCaptionPanel = React.lazy(() => import('./ClosedCaptionPanel'))
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

  handleSubmit = () => {
    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER: {
        saveMediaRecording(
          this.state.theFile,
          this.props.contextId,
          this.props.contextType,
          this.props.onDismiss
        )
        break
      }
      case PANELS.EMBED: {
        this.props.onDismiss()
        break
      }
      default:
        throw new Error('Selected Panel is invalid') // Should never get here
    }
  }

  renderFallbackSpinner = () => {
    const {LOADING_MEDIA} = this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <View as="div" height="100%" width="100%" textAlign="center">
        <Spinner renderTitle={() => LOADING_MEDIA} size="large" margin="0 0 0 medium" />
      </View>
    )
  }

  renderModalBody = () => {
    const {
      CLOSED_CAPTIONS_PANEL_TITLE,
      COMPUTER_PANEL_TITLE,
      DRAG_FILE_TEXT,
      EMBED_PANEL_TITLE,
      EMBED_VIDEO_CODE_TEXT,
      RECORD_PANEL_TITLE,
      UPLOADING_ERROR
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <Tabs
        shouldFocusOnRender
        maxWidth="large"
        onRequestTabChange={(_, {index}) => this.setState({selectedPanel: index})}
      >
        {this.props.tabs.upload && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.COMPUTER}
            renderTitle={() => COMPUTER_PANEL_TITLE}
          >
            <Suspense fallback={this.renderFallbackSpinner()}>
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
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.record && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.RECORD}
            renderTitle={() => RECORD_PANEL_TITLE}
          >
            <Suspense fallback={this.renderFallbackSpinner()}>
              <MediaRecorder
                MediaCaptureStrings={this.props.uploadMediaTranslations.MediaCaptureStrings}
                contextType={this.props.contextType}
                contextId={this.props.contextId}
                errorMessage={UPLOADING_ERROR}
                dismiss={this.props.onDismiss}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.embed && (
          <Tabs.Panel
            isSelected={this.state.selectedPanel === PANELS.EMBED}
            renderTitle={() => EMBED_PANEL_TITLE}
          >
            <Suspense fallback={this.renderFallbackSpinner()}>
              <EmbedPanel
                label={EMBED_VIDEO_CODE_TEXT}
                embedCode={this.state.embedCode}
                setEmbedCode={embedCode => this.setState({embedCode})}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        <Tabs.Panel
          isSelected={this.state.selectedPanel === PANELS.CLOSED_CAPTIONS}
          renderTitle={() => CLOSED_CAPTIONS_PANEL_TITLE}
        >
          <Suspense fallback={this.renderFallbackSpinner()}>
            <ClosedCaptionPanel
              languages={this.props.languages}
              liveRegion={this.props.liveRegion}
              uploadMediaTranslations={this.props.uploadMediaTranslations}
            />
          </Suspense>
        </Tabs.Panel>
      </Tabs>
    )
  }

  renderModalFooter = () => {
    if (this.state.selectedPanel === PANELS.RECORD) {
      return null
    }

    const {CLOSE_TEXT, SUBMIT_TEXT} = this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <Modal.Footer>
        <Button onClick={this.props.onDismiss}> {CLOSE_TEXT} </Button>
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
        size="medium"
        onDismiss={this.props.onDismiss}
        open={this.props.open}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton onClick={this.props.onDismiss} offset="medium" placement="end">
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
