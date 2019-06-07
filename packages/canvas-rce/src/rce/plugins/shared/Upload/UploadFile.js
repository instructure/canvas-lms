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
import {arrayOf, func, object, oneOf, oneOfType, string} from 'prop-types'
import {Modal} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Tabs} from '@instructure/ui-tabs'
import formatMessage from '../../../../format-message'
import indicatorRegion from '../../../indicatorRegion'
import {isImage} from '../fileTypeUtils'
import indicate from '../../../../common/indicate'

import {StoreProvider} from '../../shared/StoreContext'
import Bridge from '../../../../bridge'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const UrlPanel = React.lazy(() => import('./UrlPanel'))

/**
 * Handles uploading data based on what type of data is submitted.
 */
export const handleSubmit = (editor, accept, selectedPanel, uploadData, storeProps, afterInsert = () => {}) => {
  switch (selectedPanel) {
    case 'COMPUTER': {
      const {theFile} = uploadData
      const fileMetaData = {
        parentFolderId: 'media',
        name: theFile.name,
        size: theFile.size,
        contentType: theFile.type,
        domObject: theFile
      }
      storeProps.startMediaUpload(isImage(theFile.type) ? 'images' : 'documents', fileMetaData)
      break;
    }
    case 'UNSPLASH':
      throw new Error('Not Implemented')
    case 'URL': {
      const {fileUrl} = uploadData
      let editorHtml
      if (/image/.test(accept)) {
        editorHtml = editor.dom.createHTML('img', {src: fileUrl})
      } else {
        editorHtml = editor.dom.createHTML('a', {href: fileUrl})
      }
      editor.insertContent(editorHtml)
      break
    }
    default:
      throw new Error('Selected Panel is invalid') // Should never get here
  }
  const element = editor.selection.getEnd()
  element.addEventListener('load', () => indicate(indicatorRegion(editor, element)))
  afterInsert()
}

export function UploadFile({accept, editor, label, panels, onDismiss, onSubmit = handleSubmit}) {
  const [theFile, setFile] = useState(null)
  const [hasUploadedFile, setHasUploadedFile] = useState(false)
  const [fileUrl, setFileUrl] = useState('')
  const [selectedPanel, setSelectedPanel] = useState(panels[0])

  const trayProps = Bridge.trayProps.get(editor)

  function renderTabs() {
    return panels.map(panel => {
      switch(panel) {
        case 'COMPUTER':
          return (
            <Tabs.Panel key={panel} title={formatMessage('Computer')}>
              <Suspense fallback={<Spinner renderTitle={formatMessage('Loading')} size="large" />}>
                <ComputerPanel
                  editor={editor}
                  theFile={theFile}
                  setFile={setFile}
                  hasUploadedFile={hasUploadedFile}
                  setHasUploadedFile={setHasUploadedFile}
                  label={label}
                  accept={accept}
                />
              </Suspense>
            </Tabs.Panel>
          )
        case 'UNSPLASH':
          break;
        case 'URL':
          return (
            <Tabs.Panel key={panel} title={formatMessage('URL')}>
              <Suspense fallback={<Spinner renderTitle={formatMessage('Loading')} size="large" />}>
                <UrlPanel fileUrl={fileUrl} setFileUrl={setFileUrl} />
              </Suspense>
            </Tabs.Panel>
          )
      }
    })
  }

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Modal
          as="form"
          label={label}
          size="large"
          overflow="fit"
          onDismiss={onDismiss}
          onSubmit={e => {
            e.preventDefault()
            onSubmit(editor, accept, selectedPanel, {fileUrl, theFile}, contentProps, onDismiss)
          }}
          open
          shouldCloseOnDocumentClick
        >
          <Modal.Header>
            <CloseButton onClick={onDismiss} offset="small" placement="end">
              {formatMessage('Close')}
            </CloseButton>
            <Heading>{label}</Heading>
          </Modal.Header>
          <Modal.Body>
            <Tabs focus size="large" selectedIndex={panels.indexOf(selectedPanel)} onChange={newIndex => setSelectedPanel(panels[newIndex])}>
              {renderTabs()}
            </Tabs>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={onDismiss}>{formatMessage('Close')}</Button>&nbsp;
            <Button variant="primary" type="submit">
              {formatMessage('Submit')}
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </StoreProvider>
  )
}

UploadFile.propTypes = {
  onSubmit: func,
  onDismiss: func.isRequired,
  accept: oneOfType([arrayOf(string), string]),
  editor: object.isRequired,
  label: string.isRequired,
  panels: arrayOf(oneOf(['COMPUTER', 'UNSPLASH', 'URL']))
}

