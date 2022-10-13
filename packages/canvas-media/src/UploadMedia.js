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
import {isEqual} from 'lodash'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Tabs} from '@instructure/ui-tabs'
import {px} from '@instructure/ui-utils'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'

import {ACCEPTED_FILE_TYPES} from './acceptedMediaFileTypes'
import LoadingIndicator from './shared/LoadingIndicator'
import saveMediaRecording, {saveClosedCaptions} from './saveMediaRecording'
import translationShape from './translationShape'
import {CC_FILE_MAX_BYTES} from './shared/constants'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const MediaRecorder = React.lazy(() => import('./MediaRecorder'))

export const PANELS = {
  COMPUTER: 0,
  RECORD: 1
}

export default class UploadMedia extends React.Component {
  static propTypes = {
    disableSubmitWhileUploading: bool,
    languages: arrayOf(
      shape({
        id: string,
        label: string
      })
    ),
    liveRegion: func,
    rcsConfig: shape({
      contextId: string,
      contextType: string,
      origin: string,
      headers: shape({Authorization: string})
    }),
    onStartUpload: func,
    onUploadComplete: func,
    onDismiss: func,
    open: bool,
    tabs: shape({
      record: bool,
      upload: bool
    }),
    uploadMediaTranslations: translationShape,
    // for testing
    computerFile: instanceOf(File)
  }

  static defaultProps = {
    disableSubmitWhileUploading: false
  }

  constructor(props) {
    super(props)

    const defaultSelectedPanel = this.inferSelectedPanel(props.tabs)

    if (props.computerFile) {
      props.computerFile.title = props.computerFile.name
    }

    this.state = {
      hasUploadedFile: !!props.computerFile,
      uploading: false,
      progress: 0,
      selectedPanel: defaultSelectedPanel,
      computerFile: props.computerFile || null,
      subtitles: [],
      recordedFile: null,
      modalBodySize: {width: NaN, height: NaN}
    }

    this.modalBodyRef = React.createRef()
  }

  inferSelectedPanel = tabs => {
    let selectedPanel = -1

    if (tabs.upload) {
      selectedPanel = 0
    } else if (tabs.record) {
      selectedPanel = 1
    }

    return selectedPanel
  }

  isReady = () => {
    if (this.props.disableSubmitWhileUploading && this.state.uploading) {
      return false
    }

    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER:
        return !!this.state.computerFile
      case PANELS.RECORD:
        return !!this.state.recordedFile
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
      default:
        throw new Error('Selected Panel is invalid') // Should never get here
    }
  }

  submitEnabled = () => {
    switch (this.state.selectedPanel) {
      case PANELS.COMPUTER:
        return this.isReady() && !!this.state.computerFile?.title
      default:
        return this.isReady()
    }
  }

  uploadFile(file) {
    this.setState({uploading: true}, () => {
      this.props.onStartUpload && this.props.onStartUpload(file)
      file.userEnteredTitle = file.title
      saveMediaRecording(
        file,
        this.props.rcsConfig,
        this.saveMediaCallback,
        this.onSaveMediaProgress
      )
    })
  }

  onSaveMediaProgress = progress => {
    this.setState({progress})
  }

  saveMediaCallback = async (err, data) => {
    if (err) {
      this.props.onUploadComplete && this.props.onUploadComplete(err, data)
    } else {
      try {
        let captions
        if (this.state.selectedPanel === PANELS.COMPUTER && this.state.subtitles.length > 0) {
          captions = await saveClosedCaptions(
            data.mediaObject.media_object.media_id,
            this.state.subtitles,
            this.props.rcsConfig,
            CC_FILE_MAX_BYTES
          )
        }
        this.props.onUploadComplete && this.props.onUploadComplete(null, data, captions?.data)
      } catch (ex) {
        this.props.onUploadComplete && this.props.onUploadComplete(ex, null)
      }
    }
    this.props.onDismiss && this.props.onDismiss()
  }

  componentDidMount() {
    this.setBodySize(this.state)
  }

  componentDidUpdate(prevProps, prevState) {
    this.setBodySize(prevState)

    const invalidPanelSelected = () =>
      (this.state.selectedPanel === PANELS.COMPUTER && !this.props.tabs.upload) ||
      (this.state.selectedPanel === PANELS.RECORD && !this.props.tabs.record)

    // If the specified tabs have not changed and the selected panel is valid,
    // don't attempt to set the selected panel state (this would trigger an
    // endless loop).
    if (isEqual(prevProps.tabs, this.props.tabs) && !invalidPanelSelected()) return

    if (prevState.selectedPanel === -1 || invalidPanelSelected()) {
      // The tabs prop has changed and the selectedPanel was
      // never set in the constructor, or the selectedPanel is invalid
      // given the available tabs. Attempt to infer the selected panel
      // based on the new tabs list
      this.setState({selectedPanel: this.inferSelectedPanel(this.props.tabs)})
    }
  }

  setBodySize(state) {
    if (this.modalBodyRef.current) {
      // eslint-disable-next-line react/no-find-dom-node
      const thebody = ReactDOM.findDOMNode(this.modalBodyRef.current)
      const modalBodySize = thebody.getBoundingClientRect()
      modalBodySize.height -= px('3rem') // leave room for the tabs
      if (
        modalBodySize.width !== state.modalBodySize.width ||
        modalBodySize.height !== state.modalBodySize.height
      ) {
        if (modalBodySize.width > 0 && modalBodySize.height > 0) {
          this.setState({modalBodySize})
        }
      }
    }
  }

  renderModalBody = () => {
    const {
      COMPUTER_PANEL_TITLE,
      DRAG_FILE_TEXT,
      LOADING_MEDIA,
      RECORD_PANEL_TITLE,
      MEDIA_RECORD_NOT_AVAILABLE
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    if (!this.props.open) {
      return null
    }

    return (
      <Tabs
        maxWidth="large"
        onRequestTabChange={(_, {index}) => {
          const {tabs} = this.props
          // You can only change tabs if more than one tab is available
          if (tabs.upload && tabs.record) {
            this.setState({selectedPanel: index})
          }
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
      </Tabs>
    )
  }

  onModalClose = () => {
    this.setState({
      hasUploadedFile: false,
      selectedPanel: this.inferSelectedPanel(this.props.tabs),
      computerFile: null
    })
    this.props.onDismiss()
  }

  renderModalFooter = () => {
    if (this.state.selectedPanel === PANELS.RECORD) {
      return null
    }

    const {CLOSE_TEXT, SUBMIT_TEXT, PROGRESS_LABEL} =
      this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <Modal.Footer>
        {this.state.uploading && (
          <ProgressBar
            screenReaderLabel={PROGRESS_LABEL}
            valueNow={this.state.progress}
            valueMax={100}
            renderValue={({valueNow}) => {
              return <Text>{valueNow}%</Text>
            }}
          />
        )}
        &nbsp;
        <Button onClick={this.onModalClose}> {CLOSE_TEXT} </Button>
        &nbsp;
        <Button
          onClick={e => {
            e.preventDefault()
            this.handleSubmit()
          }}
          color="primary"
          type="submit"
          interaction={this.submitEnabled() ? 'enabled' : 'disabled'}
        >
          {SUBMIT_TEXT}
        </Button>
      </Modal.Footer>
    )
  }

  render() {
    const {CLOSE_TEXT, UPLOAD_MEDIA_LABEL} = this.props.uploadMediaTranslations.UploadMediaStrings
    const dataProps = Object.keys(this.props)
      .filter(p => /^data-/.test(p))
      .reduce((obj, key) => {
        obj[key] = this.props[key]
        return obj
      }, {})
    return (
      <Modal
        label={UPLOAD_MEDIA_LABEL}
        size="large"
        onDismiss={this.onModalClose}
        open={this.props.open}
        shouldCloseOnDocumentClick={false}
        liveRegion={this.props.liveRegion}
        {...dataProps}
      >
        <Modal.Header>
          <CloseButton
            onClick={this.onModalClose}
            offset="medium"
            placement="end"
            screenReaderLabel={CLOSE_TEXT}
          />
          <Heading>{UPLOAD_MEDIA_LABEL}</Heading>
        </Modal.Header>
        <Modal.Body ref={this.modalBodyRef}>{this.renderModalBody()}</Modal.Body>
        {this.renderModalFooter()}
      </Modal>
    )
  }
}
