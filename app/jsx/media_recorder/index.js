/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

 <Text as="div" size="small" weight="light">
   {'Pwning the order'}
 </Text>
 */

import React from 'react'
import I18n from 'i18n!media_recorder'
import { MediaCapture, canUseMediaCapture } from '@instructure/media-capture'
import { func } from 'prop-types'

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
  NOT_ALLOWED_ERROR: I18n.t('Please allow Canvas to access your webcam.'),
  NOT_READABLE_ERROR: I18n.t('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: I18n.t('Pause'),
  PLAYBACK_PLAY: I18n.t('Play'),
  PREVIEW: I18n.t('PREVIEW'),
  SAVE: I18n.t('Save'),
  SR_FILE_INPUT: I18n.t('File name'),
  START: I18n.t('Start Recording'),
  START_OVER: I18n.t('Start Over')
}

export default class CanvasMediaRecorder extends React.Component {
  static propTypes = {
    onSaveFile: func
  }

  static defaultProps = {
    onSaveFile: () => {}
  }

  saveFile = file => {
    this.props.onSaveFile(file)
  }

  render() {
    return (
      <div>
        {canUseMediaCapture() && (
          <MediaCapture
            translations={translations}
            onCompleted={this.saveFile}
          />
        )}
      </div>
    )
  }
}
