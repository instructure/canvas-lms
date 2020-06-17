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
import {arrayOf, bool, func, instanceOf, shape, string} from 'prop-types'
import React, {Suspense} from 'react'
import ReactDOM from 'react-dom'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-overlays'
import {Tabs} from '@instructure/ui-tabs'
import {px} from '@instructure/ui-utils'

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
  EMBED: 2
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
    uploadMediaTranslations: translationShape,
    // for testing
    computerFile: instanceOf(File),
    embedCode: string
  }

  constructor(props) {
    super(props)

    let defaultSelectedPanel = -1
    if (props.tabs.upload) {
      defaultSelectedPanel = 0
    } else if (props.tabs.record) {
      defaultSelectedPanel = 1
    } else if (props.tabs.embed) {
      defaultSelectedPanel = 2
    }

    this.state = {
      embedCode: props.embedCode || '',
      hasUploadedFile: false,
      selectedPanel: defaultSelectedPanel,
      computerFile: props.computerFile || null,
      subtitles: [],
      recordedFile: null,
      modalBodySize: {width: undefined, height: undefined}
    }

    this.modalBodyRef = React.createRef()
  }

  isReady = () => {
    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER:
        return !!this.state.computerFile
      case PANELS.RECORD:
        return !!this.state.recordedFile
      case PANELS.EMBED:
        return !!this.state.embedCode
      default:
        return false
    }
  }

  handleSubmit = () => {
    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER:
        this.uploadFile(this.state.computerFile)
        break
      case PANELS.RECORD:
        this.uploadFile(this.state.recordedFile)
        break
      case PANELS.EMBED: {
        this.props.onDismiss()
        this.props.onEmbed(this.state.embedCode)
        break
      }
      default:
        throw new Error('Selected Panel is invalid') // Should never get here
    }
  }

  uploadFile(file) {
    this.props.onStartUpload && this.props.onStartUpload(file)
    saveMediaRecording(file, this.props.contextId, this.props.contextType, this.saveMediaCallback)
  }

  saveMediaCallback = async (err, data) => {
    if (err) {
      this.props.onUploadComplete && this.props.onUploadComplete(err, data)
    } else {
      try {
        if (this.state.selectedPanel === PANELS.COMPUTER && this.state.subtitles.length > 0) {
          await saveClosedCaptions(data.mediaObject.media_object.media_id, this.state.subtitles)
        }
        this.props.onUploadComplete && this.props.onUploadComplete(null, data)
      } catch (ex) {
        this.props.onUploadComplete && this.props.onUploadComplete(ex, null)
      }
    }
    this.props.onDismiss && this.props.onDismiss()
  }

  componentDidUpdate(_prevProps, prevState) {
    if (this.modalBodyRef.current) {
      // eslint-disable-next-line react/no-find-dom-node
      const thebody = ReactDOM.findDOMNode(this.modalBodyRef.current)
      const modalBodySize = thebody.getBoundingClientRect()
      modalBodySize.height -= px('3rem') // leave room for the tabs
      if (
        modalBodySize.width !== prevState.modalBodySize.width ||
        modalBodySize.height !== prevState.modalBodySize.height
      ) {
        // eslint-disable-next-line react/no-did-update-set-state
        this.setState({modalBodySize})
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
        maxWidth="large"
        onRequestTabChange={(_, {index}) => {
          this.setState({selectedPanel: index})
        }}
      >
        {this.props.tabs.upload && (
          <Tabs.Panel
            key="computer"
            isSelected={this.state.selectedPanel === PANELS.COMPUTER}
            renderTitle={() => COMPUTER_PANEL_TITLE}
          >
            <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
              <ComputerPanel
                theFile={this.state.computerFile}
                setFile={file => this.setState({computerFile: file})}
                hasUploadedFile={this.state.hasUploadedFile}
                setHasUploadedFile={uploadFileState =>
                  this.setState({hasUploadedFile: uploadFileState})
                }
                label={DRAG_FILE_TEXT}
                uploadMediaTranslations={this.props.uploadMediaTranslations}
                accept={ACCEPTED_FILE_TYPES}
                languages={this.props.languages}
                liveRegion={this.props.liveRegion}
                updateSubtitles={subtitles => {
                  this.setState({subtitles})
                }}
                bounds={this.state.modalBodySize}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.record && (
          <Tabs.Panel
            key="record"
            isSelected={this.state.selectedPanel === PANELS.RECORD}
            renderTitle={() => RECORD_PANEL_TITLE}
          >
            <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
              <MediaRecorder
                MediaCaptureStrings={this.props.uploadMediaTranslations.MediaCaptureStrings}
                errorMessage={MEDIA_RECORD_NOT_AVAILABLE}
                onSave={file => this.setState({recordedFile: file}, this.handleSubmit)}
              />
            </Suspense>
          </Tabs.Panel>
        )}
        {this.props.tabs.embed && (
          <Tabs.Panel
            key="embed"
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
      computerFile: null
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
          disabled={!this.isReady()}
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
        liveRegion={this.props.liveRegion}
      >
        <Modal.Header>
          <CloseButton onClick={this.onModalClose} offset="medium" placement="end">
            {CLOSE_TEXT}
          </CloseButton>
          <Heading>{UPLOAD_MEDIA_LABEL}</Heading>
        </Modal.Header>
        <Modal.Body ref={this.modalBodyRef}>{this.renderModalBody()}</Modal.Body>
        {this.renderModalFooter()}
      </Modal>
    )
  }
}
