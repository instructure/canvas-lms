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
import {useScope as useI18nScope} from '@canvas/i18n'
import {MediaCapture, canUseMediaCapture} from '@instructure/media-capture'
import {ScreenCapture, canUseScreenCapture} from '@instructure/media-capture-new'
import {func} from 'prop-types'
import {mediaExtension} from '../../mimetypes'
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
  static propTypes = {
    onSaveFile: func,
  }

  static defaultProps = {
    onSaveFile: () => {},
  }

  saveFile = _file => {
    const file = fileWithExtension(_file)
    this.props.onSaveFile(file)
  }

  render() {
    if (ENV.studio_media_capture_enabled) {
      return (
        <div>
          {canUseScreenCapture() && (
          <ScreenCapture translations={translations} onCompleted={this.saveFile} />
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
