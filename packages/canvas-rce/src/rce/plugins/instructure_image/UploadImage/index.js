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
import {Modal, ModalHeader, ModalBody, ModalFooter} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Tabs} from '@instructure/ui-tabs'
import formatMessage from '../../../../format-message'
import indicatorRegion from "./../../../indicatorRegion";
import indicate from "../../../../common/indicate";

const UrlPanel = React.lazy(() => import('./UrlPanel'))

export const PANELS = {
  COMPUTER: 0,
  UNSPLASH: 1,
  URL: 2
}

/**
 * Handles uploading data based on what type of data is submitted.
 */
export const handleSubmit = (editor, selectedPanel, uploadData, afterInsert = () => {}) => {
  switch (selectedPanel) {
    case PANELS.COMPUTER:
      throw new Error('Not Implemented')
    case PANELS.UNSPLASH:
      throw new Error('Not Implemented')
    case PANELS.URL: {
      const {imageUrl} = uploadData
      const editorHtml = editor.dom.createHTML('img', {src: imageUrl})
      editor.insertContent(editorHtml)
      break;
    }
    default:
      throw new Error('Selected Panel is invalid') // Should never get here
  }
  const element = editor.selection.getEnd();
  element.addEventListener('load', () => indicate(indicatorRegion(editor, element)))
  afterInsert();
}

export function UploadImage({editor, onDismiss, onSubmit = handleSubmit}) {
  const [ imageUrl, setImageUrl ] = useState('');
  const [ selectedPanel, setSelectedPanel ] = useState(0)

  return (
    <Modal
      as="form"
      label={formatMessage('Upload Image')}
      size="large"
      onDismiss={onDismiss}
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit(editor, selectedPanel, { imageUrl }, onDismiss)
      }}
      open
      shouldCloseOnDocumentClick
    >
      <ModalHeader>
        <CloseButton onClick={onDismiss} offset="none" placement="end">
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{formatMessage('Upload Image')}</Heading>
      </ModalHeader>
      <ModalBody>
        <Tabs focus selectedIndex={selectedPanel} onChange={(newIndex) => setSelectedPanel(newIndex)}>
          <Tabs.Panel title={formatMessage('Computer')}>Computer Panel Here</Tabs.Panel>
          <Tabs.Panel title={formatMessage('Unsplash')}>Unsplash Panel Here</Tabs.Panel>
          <Tabs.Panel title={formatMessage('URL')}>
          <Suspense fallback={<Spinner title={formatMessage('Loading')} size="large" />}>
              <UrlPanel imageUrl={imageUrl} setImageUrl={setImageUrl} />
            </Suspense>
          </Tabs.Panel>
        </Tabs>
      </ModalBody>
      <ModalFooter>
        <Button onClick={onDismiss}>{formatMessage('Close')}</Button>&nbsp;
        <Button variant="primary" type="submit">
          {formatMessage('Submit')}
        </Button>
      </ModalFooter>
    </Modal>
  )
}

UploadImage.propTypes = {
  onDismiss: func.isRequired,
  editor: object.isRequired
}
