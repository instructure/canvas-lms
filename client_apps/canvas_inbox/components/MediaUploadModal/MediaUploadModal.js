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
// TODO: replace with frd translation function
const t = str => str

const translations = {
  ARIA_VIDEO_LABEL: () => t('Video Player'),
  ARIA_VOLUME: () => t('Current Volume Level'),
  ARIA_RECORDING: () => t('Recording'),
  DEFAULT_ERROR: () => t('Something went wrong accessing your mic or webcam.'),
  DEVICE_AUDIO: () => t('Mic'),
  DEVICE_VIDEO: () => t('Webcam'),
  FILE_PLACEHOLDER: () => t('Untitled'),
  FINISH: () => t('Finish'),
  NO_WEBCAM: () => t('No Video'),
  NOT_ALLOWED_ERROR: () => t('Please allow Canvas to access your microphone and webcam.'),
  NOT_READABLE_ERROR: () => t('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: () => t('Pause'),
  PLAYBACK_PLAY: () => t('Play'),
  PREVIEW: () => t('PREVIEW'),
  SAVE: () => t('Save'),
  SR_FILE_INPUT: () => t('File name'),
  START: () => t('Start Recording'),
  START_OVER: () => t('Start Over')
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
      label={t('Record/Upload Media Comment')}
      onClose={onClose}
      onOpen={onOpen}
      open={open}
      size="medium"
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <Heading>{t('Record/Upload Media Comment')}</Heading>
        <CloseButton
          data-test="CloseBtn"
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <Tabs onRequestTabChange={handleTabChange}>
          <Tabs.Panel renderTitle={t('Record Media')} isSelected={selectedTab === 0}>
            {canUseMediaCapture() && (
              <MediaCapture
                onCompleted={onRecordingSave}
                translations={mapObject(translations, f => f.call())}
              />
            )}
          </Tabs.Panel>
          <Tabs.Panel renderTitle={t('Upload Media')} isSelected={selectedTab === 1}>
            <label htmlFor="media-upload-file-input">
              <ScreenReaderContent>{t('File Upload')}</ScreenReaderContent>
            </label>
            <input
              id="media-upload-file-input"
              hidden
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
              {t('Select Audio File')}
            </Button>
            <Button
              onClick={() => hiddenFileInput.current.click()}
              renderIcon={<IconVideoCameraSolid />}
            >
              {t('Select Video File')}
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
  open: PropTypes.bool
}

MediaUploadModal.defaultProps = {
  onClose: () => {},
  onOpen: () => {},
  open: false
}

export default MediaUploadModal
