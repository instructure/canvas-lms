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

import {Button, CloseButton} from '@instructure/ui-buttons'
import formatMessage from '../../../../format-message'
import {func, object} from 'prop-types'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import React, {Suspense, useState} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-layout'

import Bridge from '../../../../bridge'
import {StoreProvider} from '../../shared/StoreContext'

const MediaRecorder = React.lazy(() => import('./MediaRecorder'))
const EmbedPanel = React.lazy(() => import('./EmbedPanel'))

export const PANELS = {
  COMPUTER: 0,
  RECORD: 1,
  EMBED: 2
}

export const handleSubmit = (editor, selectedPanel, uploadData, onDismiss) => {
  switch (selectedPanel) {
    case PANELS.COMPUTER: {
      throw new Error('not yet implemented')
    }
    case PANELS.EMBED: {
      const {embedCode} = uploadData
      editor.insertContent(embedCode)
      onDismiss()
      break
    }
    default:
      throw new Error('Selected Panel is invalid') // Should never get here
  }
}

export function UploadMedia(props) {
  const [ selectedPanel, setSelectedPanel ] = useState(0)
  const trayProps = Bridge.trayProps.get(props.editor)
  const [embedCode, setEmbedCode] = useState('')

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Modal
          label={formatMessage('Upload Media')}
          size="medium"
          onDismiss={props.onDismiss}
          open
          shouldCloseOnDocumentClick
        >
          <Modal.Header>
            <CloseButton onClick={props.onDismiss} offset="medium" placement="end">
              {formatMessage('Close')}
            </CloseButton>
            <Heading>{formatMessage('Upload Media')}</Heading>
          </Modal.Header>
          <Modal.Body>
            <Tabs focus size="large" selectedIndex={selectedPanel} onChange={newIndex => setSelectedPanel(newIndex)}>
              <Tabs.Panel title={formatMessage('Computer')}>Computer Panel Here</Tabs.Panel>
              <Tabs.Panel title={formatMessage('Record')}>
                <Suspense fallback={
                  <View as="div" height="100%" width="100%" textAlign="center">
                    <Spinner renderTitle={formatMessage('Loading media')} size="large" margin="0 0 0 medium" />
                  </View>
                }>
                  <MediaRecorder editor={props.editor} dismiss={props.onDismiss} contentProps={contentProps}/>
                </Suspense>
              </Tabs.Panel>
              <Tabs.Panel title={formatMessage('Embed')}>
                <Suspense fallback={
                  <View as="div" height="100%" width="100%" textAlign="center">
                    <Spinner renderTitle={formatMessage('Loading media')} size="large" margin="0 0 0 medium" />
                  </View>
                }>
                  <EmbedPanel embedCode={embedCode} setEmbedCode={setEmbedCode} />
                </Suspense>
              </Tabs.Panel>
            </Tabs>
          </Modal.Body>
          {selectedPanel !== PANELS.RECORD &&
            <Modal.Footer>
              <Button onClick={props.onDismiss}>{formatMessage('Close')}</Button>&nbsp;
              <Button
                onClick={e => {
                  e.preventDefault()
                  handleSubmit(props.editor, selectedPanel, {embedCode},  props.onDismiss)
                }}
                variant="primary"
                type="submit">
                {formatMessage('Submit')}
              </Button>
            </Modal.Footer>
          }
        </Modal>
      )}
    </StoreProvider>
  )
}

UploadMedia.propTypes = {
  onDismiss: func.isRequired,
  editor: object.isRequired
}
