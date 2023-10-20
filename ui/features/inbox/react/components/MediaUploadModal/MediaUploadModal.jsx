/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconAudioSolid, IconVideoCameraSolid} from '@instructure/ui-icons'
import {MediaCapture, canUseMediaCapture} from '@instructure/media-capture'
import {Modal} from '@instructure/ui-modal'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tabs} from '@instructure/ui-tabs'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conversations_2')

const translations = {
  ARIA_VIDEO_LABEL: () => I18n.t('Video Player'),
  ARIA_VOLUME: () => I18n.t('Current Volume Level'),
  ARIA_RECORDING: () => I18n.t('Recording'),
  DEFAULT_ERROR: () => I18n.t('Something went wrong accessing your mic or webcam.'),
  DEVICE_AUDIO: () => I18n.t('Mic'),
  DEVICE_VIDEO: () => I18n.t('Webcam'),
  FILE_PLACEHOLDER: () => I18n.t('Untitled'),
  FINISH: () => I18n.t('Finish'),
  NO_WEBCAM: () => I18n.t('No Video'),
  NOT_ALLOWED_ERROR: () => I18n.t('Please allow Canvas to access your microphone and webcam.'),
  NOT_READABLE_ERROR: () => I18n.t('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: () => I18n.t('Pause'),
  PLAYBACK_PLAY: () => I18n.t('Play'),
  PREVIEW: () => I18n.t('PREVIEW'),
  SAVE: () => I18n.t('Save'),
  SR_FILE_INPUT: () => I18n.t('File name'),
  START: () => I18n.t('Start Recording'),
  START_OVER: () => I18n.t('Start Over'),
}

// Function for applying a function to each value of an object, returning a new object
const mapObject = (obj, fn) => {
  return Object.fromEntries(Object.entries(obj).map(([k, v], i) => [k, fn(v, k, i)]))
}

export function MediaUploadModal({onClose, onFileUpload, onOpen, onRecordingSave, open}) {
  const hiddenFileInput = React.useRef(null)
  const [selectedTab, setTab] = React.useState(0)

  const handleTabChange = (event, {index}) => {
    setTab(index)
  }

  return (
    <Modal
      label={I18n.t('Record/Upload Media Comment')}
      onClose={onClose}
      onOpen={onOpen}
      open={open}
      size="medium"
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <Heading>{I18n.t('Record/Upload Media Comment')}</Heading>
        <CloseButton
          data-test="CloseBtn"
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <Tabs onRequestTabChange={handleTabChange}>
          <Tabs.Panel renderTitle={I18n.t('Record Media')} isSelected={selectedTab === 0}>
            {canUseMediaCapture() && (
              <MediaCapture
                onCompleted={onRecordingSave}
                translations={mapObject(translations, f => f.call())}
              />
            )}
          </Tabs.Panel>
          <Tabs.Panel renderTitle={I18n.t('Upload Media')} isSelected={selectedTab === 1}>
            <label htmlFor="media-upload-file-input">
              <ScreenReaderContent>{I18n.t('File Upload')}</ScreenReaderContent>
            </label>
            <input
              id="media-upload-file-input"
              hidden={true}
              onChange={e => {
                onFileUpload(e.target.files)
              }}
              type="file"
              ref={hiddenFileInput}
            />
            <Button
              margin="auto small auto auto"
              onClick={() => hiddenFileInput.current.click()}
              renderIcon={<IconAudioSolid />}
            >
              {I18n.t('Select Audio File')}
            </Button>
            <Button
              onClick={() => hiddenFileInput.current.click()}
              renderIcon={<IconVideoCameraSolid />}
            >
              {I18n.t('Select Video File')}
            </Button>
          </Tabs.Panel>
        </Tabs>
      </Modal.Body>
    </Modal>
  )
}

MediaUploadModal.propTypes = {
  onClose: PropTypes.func,
  onFileUpload: PropTypes.func.isRequired,
  onOpen: PropTypes.func,
  onRecordingSave: PropTypes.func.isRequired,
  open: PropTypes.bool,
}

MediaUploadModal.defaultProps = {
  onClose: () => {},
  onOpen: () => {},
  open: false,
}

export default MediaUploadModal
