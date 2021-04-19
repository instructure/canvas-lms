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

import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton} from '@instructure/ui-buttons'
import formatMessage from '../../../../format-message'
import {func, object} from 'prop-types'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Modal} from '@instructure/ui-modal'
import {Mask} from '@instructure/ui-overlays'
import React, {Suspense, useState} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'

import Bridge from '../../../../bridge'
import {StoreProvider} from '../../shared/StoreContext'

const MediaRecorder = React.lazy(() => import('./MediaRecorder'))
const ComputerPanel = React.lazy(() => import('../../shared/Upload/ComputerPanel'))

export const PANELS = {
  COMPUTER: 0,
  RECORD: 1
}

const ALERT_TIMEOUT = 5000
const ACCEPTED_FILE_TYPES = [
  '3gp',
  'aac',
  'amr',
  'asf',
  'avi',
  'flac',
  'flv',
  'm4a',
  'm4v',
  'mkv',
  'mov',
  'mp3',
  'mp4',
  'mpeg',
  'mpg',
  'ogg',
  'qt',
  'wav',
  'wma',
  'wmv'
]

export const handleSubmit = (editor, selectedPanel, uploadData, saveMediaRecording, onDismiss) => {
  const {theFile} = uploadData
  saveMediaRecording('media', theFile)
  onDismiss()
}

function renderLoading() {
  return formatMessage('Loading')
}

function renderLoadingMedia() {
  return formatMessage('Loading media')
}

function loadingErrorSuccess(states) {
  if (states.uploadingMediaStatus.loading) {
    return (
      <Mask>
        <Spinner renderTitle={renderLoading} size="large" margin="0 0 0 medium" />
      </Mask>
    )
  } else if (states.uploadingMediaStatus.error) {
    return (
      <Alert variant="error" margin="small" timeout={ALERT_TIMEOUT}>
        {formatMessage('Error uploading video/audio recording')}
      </Alert>
    )
  } else if (states.uploadingMediaStatus.uploaded) {
    return <Alert timeout={ALERT_TIMEOUT}>{formatMessage('Video/audio recording uploaded')}</Alert>
  }
}

export function UploadMedia(props) {
  const [theFile, setFile] = useState(null)
  const [hasUploadedFile, setHasUploadedFile] = useState(false)
  const [selectedPanel, setSelectedPanel] = useState(0)
  const trayProps = Bridge.trayProps.get(props.editor)

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Modal
          label={formatMessage('Upload Media')}
          size="medium"
          onDismiss={props.onDismiss}
          open
          shouldCloseOnDocumentClick={false}
        >
          <Modal.Header>
            <CloseButton onClick={props.onDismiss} offset="medium" placement="end">
              {formatMessage('Close')}
            </CloseButton>
            <Heading>{formatMessage('Upload Media')}</Heading>
          </Modal.Header>
          <Modal.Body>
            {loadingErrorSuccess(contentProps.upload)}
            <Tabs
              shouldFocusOnRender
              size="large"
              selectedIndex={selectedPanel}
              onRequestTabChange={newIndex => setSelectedPanel(newIndex)}
            >
              <Tabs.Panel title={formatMessage('Computer')}>
                <Suspense
                  fallback={
                    <View as="div" height="100%" width="100%" textAlign="center">
                      <Spinner
                        renderTitle={renderLoadingMedia}
                        size="large"
                        margin="0 0 0 medium"
                      />
                    </View>
                  }
                  size="large"
                >
                  <ComputerPanel
                    editor={props.editor}
                    theFile={theFile}
                    setFile={setFile}
                    hasUploadedFile={hasUploadedFile}
                    setHasUploadedFile={setHasUploadedFile}
                    label={formatMessage('Drag a File Here')}
                    accept={ACCEPTED_FILE_TYPES}
                  />
                </Suspense>
              </Tabs.Panel>
              <Tabs.Panel title={formatMessage('Record')}>
                <Suspense
                  fallback={
                    <View as="div" height="100%" width="100%" textAlign="center">
                      <Spinner
                        renderTitle={renderLoadingMedia}
                        size="large"
                        margin="0 0 0 medium"
                      />
                    </View>
                  }
                >
                  <MediaRecorder
                    editor={props.editor}
                    dismiss={props.onDismiss}
                    contentProps={contentProps}
                  />
                </Suspense>
              </Tabs.Panel>
            </Tabs>
          </Modal.Body>
          {selectedPanel !== PANELS.RECORD && (
            <Modal.Footer>
              <Button onClick={props.onDismiss}>{formatMessage('Close')}</Button>&nbsp;
              <Button
                onClick={e => {
                  e.preventDefault()
                  handleSubmit(
                    props.editor,
                    selectedPanel,
                    {theFile},
                    contentProps.saveMediaRecording,
                    props.onDismiss
                  )
                }}
                variant="primary"
                type="submit"
              >
                {formatMessage('Submit')}
              </Button>
            </Modal.Footer>
          )}
        </Modal>
      )}
    </StoreProvider>
  )
}

UploadMedia.propTypes = {
  onDismiss: func.isRequired,
  editor: object.isRequired
}
