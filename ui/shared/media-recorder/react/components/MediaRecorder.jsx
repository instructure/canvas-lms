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

import {useScope as createI18nScope} from '@canvas/i18n'
import {MediaCapture, canUseMediaCapture} from '@instructure/media-capture'
import {ScreenCapture, canUseScreenCapture} from '@instructure/media-capture-new'
import $ from 'jquery'
import {func, string} from 'prop-types'
import React from 'react'
import ReactDOM from 'react-dom'
import {mediaExtension} from '../../mimetypes'

import {Spinner} from '@instructure/ui-spinner'
import {IconRecordSolid, IconStopLine} from '@instructure/ui-icons'

import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('media_recorder')
const DEFAULT_EXTENSION = 'webm'
const fileExtensionRegex = /\.\S/

const translations = {
  ARIA_TIMEBAR_LABEL: I18n.t('Timebar'),
  ARIA_VIDEO_LABEL: I18n.t('Video Player'),
  ARIA_VOLUME: I18n.t('Current Volume Level'),
  CAPTIONS_OFF: I18n.t('Captions Off'),
  FILE_PLACEHOLDER: I18n.t('Untitled'),
  FINISH: I18n.t('Finish'),
  FULL_SCREEN: I18n.t('Full Screen'),
  MICROPHONE_DISABLED: I18n.t('Microphone Disabled'),
  PLAYBACK_PAUSE: I18n.t('Pause'),
  PLAYBACK_PLAY: I18n.t('Play'),
  PLAYBACK_SPEED: I18n.t('Playback Speed'),
  SAVE_MEDIA: I18n.t('Save Media'),
  DEFAULT_ERROR: I18n.t('Something went wrong. Please try again.'),
  SOURCE_CHOOSER: I18n.t('Media Quality'),
  SR_FILE_INPUT: I18n.t('Title'),
  START: I18n.t('Start Recording'),
  START_OVER: I18n.t('Start Over'),
  VIDEO_TRACK: I18n.t('Closed Captioning'),
  VOLUME_MUTED: I18n.t('Muted'),
  VOLUME_UNMUTED: I18n.t('Volume'),
  WEBCAM_DISABLED: I18n.t('Webcam Disabled'),
  WINDOWED_SCREEN: I18n.t('Windowed Screen'),
  BACK: I18n.t('Back'),
  STANDARD: I18n.t('Standard'),
  OFF: I18n.t('Off'),
  CAPTIONS: I18n.t('Captions'),
  SPEED: I18n.t('Speed'),
  QUALITY: I18n.t('Quality'),
  PLAYER_SETTINGS: I18n.t('Player Settings'),
  SETTINGS: I18n.t('Settings'),
  TOGGLE_CAPTIONS_ON: I18n.t('Toggle Captions On'),
  TOGGLE_CAPTIONS_OFF: I18n.t('Toggle Captions Off'),
  ON_TOP: I18n.t('On Top'),
  PLACE_CAPTION_TO_BOTTOM: I18n.t('Place caption to bottom'),
  PLACE_CAPTION_TO_TOP: I18n.t('Place caption to top'),
  INVERT_COLORS: I18n.t('Invert Colors'),
  CHANGE_CAPTION_COLOR_TO_LIGHT_THEME: I18n.t('Change caption color to light theme'),
  CHANGE_CAPTION_COLOR_TO_DARK_THEME: I18n.t('Change caption color to dark theme'),
  SIZE: I18n.t('Size'),
  NORMAL: I18n.t('Normal'),
  LARGE: I18n.t('Large'),
  X_LARGE: I18n.t('Extra Large'),
  WEBCAM_VIDEO_SELECTION_LABEL: I18n.t('Select video source'),
  WEBCAM_AUDIO_SELECTION_LABEL: I18n.t('Select audio source'),
  COMMENTS: I18n.t('Comments'),
  LANGUAGE: I18n.t('Language'),
  SCREEN_SHARING_CONTROL: I18n.t('Screen Capture'),
  SCREEN_SHARING_CONTROL_LABEL_ACTIVATE: I18n.t('Screen sharing enabled'),
  SCREEN_SHARING_CONTROL_LABEL_DEACTIVATE: I18n.t('Screen sharing disabled'),
  SCREEN_SHARING_CONTROL_ACTIVATE: I18n.t('Enabled'),
  SCREEN_SHARING_CONTROL_DEACTIVATE: I18n.t('Disabled'),
  PAUSE: I18n.t('Pause'),
  CONTINUE: I18n.t('Continue'),
  PAUSED_VIDEO: I18n.t('Recording is paused'),
  PICTURE_IN_PICTURE: I18n.t('Picture-in-Picture'),
  PICTURE_IN_PICTURE_TOOLTIP: I18n.t('To enable your webcam, share your entire screen.'),
  PICTURE_IN_PICTURE_MODAL_HEADING: I18n.t('Enable camera'),
  PICTURE_IN_PICTURE_MODAL_BODY: I18n.t(
    'Would you like to enable your camera during full screen recording?',
  ),
  PICTURE_IN_PICTURE_MODAL_CANCEL: I18n.t('No'),
  PICTURE_IN_PICTURE_MODAL_CONFIRM: I18n.t('Yes'),
  PICTURE_IN_PICTURE_MODAL_CLOSE: I18n.t('Close'),
  ERROR_SCREEN_SHARING_SYSTEM_PERMISSION: I18n.t(
    'Unable to share your screen. Please review your system permissions and try again.',
  ),
  NO_SYSTEM_PERMISSION_OVERLAY_HEADING: I18n.t('Give your browser permission to record'),
  NO_SYSTEM_PERMISSION_OVERLAY_TEXT: I18n.t(
    'Grant your browser permission to record by allowing access to your camera and microphone.',
  ),
  NO_SYSTEM_PERMISSION_OVERLAY_LINK: I18n.t('Learn more ...'),
  NO_SYSTEM_VIDEO_PERMISSION_TOOLTIP: I18n.t("Please check your system's camera settings."),
  NO_SYSTEM_AUDIO_PERMISSION_TOOLTIP: I18n.t("Please check your system's microphone settings."),
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

  renderSavingSpinner = () => {
    const dialog = document.querySelector('.ui-dialog:not([style*="display: none"])')
    const dialogContent = dialog?.querySelector('.ui-dialog-content')

    if (dialogContent) {
      const dialogButtons = dialog.querySelector('.ui-dialog-buttonpane')
      if (dialogButtons) {
        dialogButtons.style.display = 'none'
      }

      const spinnerContainer = document.createElement('div')
      spinnerContainer.id = 'media-spinner-container'
      dialogContent.innerHTML = ''
      dialogContent.appendChild(spinnerContainer)

      ReactDOM.render(
        <div style={{padding: '2rem', textAlign: 'center'}}>
          <div style={{marginBottom: '1rem'}}>
            <Spinner renderTitle={I18n.t('Saving media file')} size="large" />
          </div>
          <div style={{fontSize: '16px', color: '#333'}}>
            {I18n.t(
              'Saving your file. Please wait and the modal will close when the upload is finished.',
            )}
          </div>
        </div>,
        spinnerContainer,
      )
    }
  }

  saveFile = _file => {
    this.renderSavingSpinner()
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
        mountPoint,
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
    const closeButton = dialog.querySelector('button.ui-dialog-titlebar-close')
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

  handleStopShareClick = status => {
    if (status === 'PREVIEWSAVE') {
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
