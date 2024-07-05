/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {MediaCapture, canUseMediaCapture} from '@instructure/media-capture'
import {ScreenCapture, canUseScreenCapture} from '@instructure/media-capture-new'
import {func, string} from 'prop-types'
import {mediaExtension} from '../../mimetypes'

import {IconRecordSolid, IconStopLine} from '@instructure/ui-icons'

import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('media_recorder')
const DEFAULT_EXTENSION = 'webm'
const fileExtensionRegex = /\.\S/

const translations = {
  ARIA_VIDEO_LABEL: I18n.t('Video Player'),
  ARIA_VOLUME: I18n.t('Current Volume Level'),
  ARIA_RECORDING: I18n.t('Recording'),
  DEFAULT_ERROR: I18n.t('Something went wrong accessing your mic or webcam.'),
  DEVICE_AUDIO: I18n.t('Mic'),
  DEVICE_VIDEO: I18n.t('Webcam'),
  FILE_PLACEHOLDER: I18n.t('Untitled'),
  FINISH: I18n.t('Finish'),
  NO_WEBCAM: I18n.t('No Video'),
  NOT_ALLOWED_ERROR: I18n.t('Please allow Canvas to access your microphone and webcam.'),
  NOT_READABLE_ERROR: I18n.t('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: I18n.t('Pause'),
  PLAYBACK_PLAY: I18n.t('Play'),
  PREVIEW: I18n.t('PREVIEW'),
  SAVE: I18n.t('Save'),
  SR_FILE_INPUT: I18n.t('File name'),
  START: I18n.t('Start Recording'),
  START_OVER: I18n.t('Start Over'),
}

export function fileWithExtension(file) {
  if (fileExtensionRegex.test(file.name)) {
    return file
  }
  const extension = mediaExtension(file.type) || DEFAULT_EXTENSION
  const name = file.name?.endsWith('.') ? `${file.name}${extension}` : `${file.name}.${extension}`
  return new File([file], name, {
    type: file.type,
    lastModified: file.lastModified,
  })
}

export default class CanvasMediaRecorder extends React.Component {
  dialogRef = React.createRef()

  static propTypes = {
    onSaveFile: func,
    onModalShowToggle: func,
    indicatorBarMountPointId: string,
  }

  static defaultProps = {
    onSaveFile: () => {},
  }

  saveFile = _file => {
    const file = fileWithExtension(_file)
    this.props.onSaveFile(file)
  }

  screenCaptureStarted = () => {
    const finishButton = document.querySelector('#screen_capture_finish_button')
    return finishButton?.getAttribute('data-is-screen-share') === 'true'
  }

  onRecordingStart = () => {
    if (this.screenCaptureStarted()) {
      this.hideModal()
      this.renderIndicatorBar()
    }
  }

  renderIndicatorBar = () => {
    const {indicatorBarMountPointId} = this.props
    if (!indicatorBarMountPointId) return
    const mountPoint = document.getElementById(indicatorBarMountPointId)
    if (mountPoint) {
      ReactDOM.render(
        <ScreenCaptureIndicatorBar
          onFinishClick={this.handleFinishClick}
          onCancelClick={this.handleCancelClick}
        />,
        mountPoint
      )
    }
  }

  removeIndicatorBar = () => {
    const {indicatorBarMountPointId} = this.props
    const mountPoint = document.getElementById(indicatorBarMountPointId)
    ReactDOM.unmountComponentAtNode(mountPoint)
  }

  handleCancelClick = () => {
    const dialog = this.dialogRef.current
    this.removeIndicatorBar()
    this.toggleBackgroundItems(false)
    const closeButton = dialog.querySelector('a.ui-dialog-titlebar-close')
    closeButton?.click()
  }

  handleFinishClick = () => {
    const dialog = this.dialogRef.current
    const finishButton = dialog.querySelector('#screen_capture_finish_button')
    finishButton?.click()
    this.showModal()
    this.dialogRef.current = null
    this.removeIndicatorBar()
  }

  showModal = () => {
    const dialog = this.dialogRef.current
    if (dialog) {
      dialog.style.display = 'block'
      this.toggleBackgroundItems(false)
    }
  }

  hideModal = () => {
    const dialog = document.querySelectorAll('.ui-dialog:not([style*="display: none"])')[0]
    dialog.style.display = 'none'
    this.toggleBackgroundItems(true)
    this.dialogRef.current = dialog
  }

  toggleBackgroundItems = disabled => {
    // toggle the modal's backgroud overlay
    const overlay = document.querySelector('.ui-widget-overlay')
    if (overlay) {
      overlay.style.display = disabled ? 'none' : 'block'
      // enables anchors and inputs on the page behind the hidden modal
      $.ui.dialog.overlay.maxZ = disabled ? 0 : 1000
    }

    if (this.props.onModalShowToggle) {
      this.props.onModalShowToggle(disabled)
    }
  }

  handleStopShareClick = (status) => {
    if (status === "PREVIEWSAVE") {
      this.showModal()
      this.removeIndicatorBar()
    }
  }

  render() {
    if (ENV.studio_media_capture_enabled) {
      return (
        <div>
          {canUseScreenCapture() && (
            <ScreenCapture
              translations={translations}
              onCompleted={this.saveFile}
              onChange={this.handleStopShareClick}
              // give the finish button time to render, that's how we tell if it's a screen share
              onStreamInitialized={() => setTimeout(this.onRecordingStart, 250)}
              // allows you to include the current tab in the screen share
              experimentalScreenShareOptions={{selfBrowserSurface: 'include'}}
            />
          )}
        </div>
      )
    }
    return (
      <div>
        {canUseMediaCapture() && (
          <MediaCapture translations={translations} onCompleted={this.saveFile} />
        )}
      </div>
    )
  }
}

const ScreenCaptureIndicatorBar = ({onCancelClick, onFinishClick}) => {
  return (
    <View as="div" className="RecordingBar" padding="x-small small">
      <View margin="0 auto 0 0" className="RecordingBar__time">
        <View className="RecordingBar__icon">
          <IconRecordSolid color="error" />
        </View>
        <Heading level="reset" as="h2">
          {I18n.t('Screen recording is in progress ')}
        </Heading>
      </View>
      <Button
        color="secondary"
        withBackground={true}
        margin="none"
        size="medium"
        onClick={onCancelClick}
        id="screen_capture_bar_cancel_button"
      >
        {I18n.t('Cancel')}
      </Button>
      <Button
        renderIcon={IconStopLine}
        color="primary"
        size="medium"
        margin="none"
        onClick={onFinishClick}
        id="screen_capture_bar_finish_button"
        themeOverride={{
          iconSizeMedium: '1.125rem',
        }}
      >
        {I18n.t('Finish Recording')}
      </Button>
    </View>
  )
}
