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

import React, {Suspense, useState} from 'react'
import {func, object} from 'prop-types'
import {Modal} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Tabs} from '@instructure/ui-tabs'
import formatMessage from '../../../../format-message'

import {StoreProvider} from '../../shared/StoreContext'
import Bridge from '../../../../bridge'

const MediaRecorder = React.lazy(() => import('./MediaRecorder'))
const UrlPanel = React.lazy(() => import('./UrlPanel'))

export function UploadMedia(props) {
  const [ imageUrl, setImageUrl ] = useState('');
  const [ selectedPanel, setSelectedPanel ] = useState(0)
  const trayProps = Bridge.trayProps.get(props.editor)

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Modal
          label={formatMessage('Upload Media')}
          size="large"
          onDismiss={props.onDismiss}
          onSubmit={() => {}}
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
            <Tabs selectedIndex={selectedPanel} onChange={(newIndex) => setSelectedPanel(newIndex)}>
              <Tabs.Panel title={formatMessage('Computer')}>Computer Panel Here</Tabs.Panel>
              <Tabs.Panel title={formatMessage('Record')}>
                <Suspense fallback={<Spinner title={formatMessage('Loading')} size="large" />}>
                  <MediaRecorder editor={props.editor} contentProps={contentProps}/>
                </Suspense>
              </Tabs.Panel>
              <Tabs.Panel title={formatMessage('URL')}>
              <Suspense fallback={<Spinner title={formatMessage('Loading')} size="large" />}>
                  <UrlPanel imageUrl={imageUrl} setImageUrl={setImageUrl} />
                </Suspense>
              </Tabs.Panel>
            </Tabs>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={props.onDismiss}>{formatMessage('Close')}</Button>&nbsp;
            <Button variant="primary" type="submit">
              {formatMessage('Submit')}
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </StoreProvider>
  )
}

UploadMedia.propTypes = {
  onDismiss: func.isRequired,
  editor: object.isRequired
}
