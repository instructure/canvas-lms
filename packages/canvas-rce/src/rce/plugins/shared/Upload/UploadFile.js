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

import React, {useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import {arrayOf, bool, func, object, oneOf, oneOfType, string} from 'prop-types'
import {px} from '@instructure/ui-utils'
import indicatorRegion from '../../../indicatorRegion'
import {isImage, isAudioOrVideo} from '../fileTypeUtils'
import indicate from '../../../../common/indicate'

import {StoreProvider} from '../StoreContext'

import Bridge from '../../../../bridge'
import UploadFileModal from './UploadFileModal'

/**
 * Handles uploading data based on what type of data is submitted.
 */
export const handleSubmit = (
  editor,
  accept,
  selectedPanel,
  uploadData,
  storeProps,
  source,
  afterInsert = () => {}
) => {
  Bridge.focusEditor(editor.rceWrapper) // necessary since it blurred when the modal opened
  const {altText, isDecorativeImage, displayAs} = uploadData?.imageOptions || {}
  switch (selectedPanel) {
    case 'COMPUTER': {
      const {theFile} = uploadData
      const fileMetaData = {
        parentFolderId: 'media',
        name: theFile.name,
        size: theFile.size,
        contentType: theFile.type,
        domObject: theFile,
        altText,
        isDecorativeImage,
        displayAs,
        usageRights:
          uploadData?.usageRights?.usageRight === 'choose' ? undefined : uploadData?.usageRights,
      }
      let tabContext = 'documents'
      if (isImage(theFile.type)) {
        tabContext = 'images'
      } else if (isAudioOrVideo(theFile.type)) {
        tabContext = 'media'
      }
      storeProps.startMediaUpload(tabContext, fileMetaData)
      break
    }
    case 'URL': {
      const {fileUrl} = uploadData
      let editorHtml
      if (displayAs !== 'link' && /image/.test(accept)) {
        editorHtml = editor.dom.createHTML('img', {
          src: fileUrl,
          alt: altText,
          role: isDecorativeImage ? 'presentation' : undefined,
        })
      } else {
        editorHtml = editor.dom.createHTML('a', {href: fileUrl}, altText || fileUrl)
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

export function UploadFile({
  accept,
  editor,
  label,
  panels,
  onDismiss,
  requireA11yAttributes = true,
  trayProps,
  canvasOrigin,
  onSubmit = handleSubmit,
  preselectedFile = undefined,
}) {
  const [modalBodyWidth, setModalBodyWidth] = useState(undefined)
  const [modalBodyHeight, setModalBodyHeight] = useState(undefined)
  const [theFile] = useState(preselectedFile)
  const bodyRef = React.useRef()

  trayProps = trayProps || Bridge.trayProps.get(editor)

  // the panels get rendered inside tab panels. it's difficult for them to
  // figure out how much space they have to work with, and I'd like the previews
  // not to trigger scrollbars in the modal's body. Get the Modal.Body's size
  // and to the ComputerPanel how much space it has so it can render the file preview
  useEffect(() => {
    if (bodyRef.current) {
      // eslint-disable-next-line react/no-find-dom-node
      const thebody = ReactDOM.findDOMNode(bodyRef.current)
      const sz = thebody.getBoundingClientRect()
      sz.height -= px('3rem') // leave room for the tabs
      setModalBodyWidth(sz.width)
      setModalBodyHeight(sz.height)
    }
  }, [modalBodyHeight, modalBodyWidth])

  return (
    <StoreProvider {...trayProps} canvasOrigin={canvasOrigin}>
      {contentProps => (
        <UploadFileModal
          ref={bodyRef}
          preselectedFile={theFile}
          editor={editor}
          trayProps={trayProps}
          contentProps={contentProps}
          canvasOrigin={canvasOrigin}
          onSubmit={onSubmit}
          onDismiss={onDismiss}
          panels={panels}
          label={label}
          accept={accept}
          modalBodyWidth={modalBodyWidth}
          modalBodyHeight={modalBodyHeight}
          requireA11yAttributes={requireA11yAttributes}
        />
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
  panels: arrayOf(oneOf(['COMPUTER', 'URL'])),
  requireA11yAttributes: bool,
  trayProps: object,
  canvasOrigin: string,
  preselectedFile: object, // a JS File
}
