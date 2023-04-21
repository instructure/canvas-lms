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

import React from 'react'
import ReactDOM from 'react-dom'
import Bridge from '../../../bridge'
import {StoreProvider} from '../shared/StoreContext'
import formatMessage from '../../../format-message'
import {headerFor, originFromHost} from '../../../rcs/api'
import {instuiPopupMountNode} from '../../../util/fullscreenHelpers'
import RCEGlobals from '../../RCEGlobals'

export const handleUpload = (error, uploadData, onUploadComplete, uploadBookmark) => {
  let err_msg = error && Bridge.uploadMediaTranslations.UploadMediaStrings.UPLOADING_ERROR

  if (error?.name === 'FileSizeError') {
    err_msg = formatMessage(
      'Size of caption file is greater than the maximum {max} kb allowed file size.',
      {max: error.maxBytes / 1000}
    )
  }

  const editorComponent = Bridge.activeEditor()
  let newBookmark
  if (uploadBookmark) {
    newBookmark = editorComponent.editor.selection.getBookmark(2, true)
    editorComponent.editor.selection.moveToBookmark(uploadBookmark)
  }
  onUploadComplete(err_msg, uploadData)
  if (newBookmark) {
    editorComponent.editor.selection.moveToBookmark(newBookmark)
  }
}

export default function (ed, document) {
  return import('@instructure/canvas-media').then(CanvasMedia => {
    const UploadMedia = CanvasMedia.default
    let container = document.querySelector('.canvas-rce-media-upload')
    if (!container) {
      container = document.createElement('div')
      container.className = 'canvas-rce-media-upload'
      document.body.appendChild(container)
    }

    const handleDismiss = () => {
      ReactDOM.unmountComponentAtNode(container)
      ed.focus(false)
    }

    // We need to have a place to store the bookmark location
    // while the upload happens.
    let uploadBookmark = null

    // redux's activateMediaUpload action does the image placeholder,
    // but it also does the upload. We need to separate them if we
    // want to stay within the redux approach
    const handleStartUpload = fileProps => {
      Bridge.focusEditor(ed.rceWrapper)
      const editorComponent = Bridge.activeEditor()
      uploadBookmark = editorComponent?.editor?.selection.getBookmark(2, true)
      Bridge.insertImagePlaceholder(fileProps)
      handleDismiss()
    }

    const trayProps = Bridge.trayProps.get(ed)

    ReactDOM.render(
      <StoreProvider {...trayProps}>
        {contentProps => (
          <UploadMedia
            data-mce-component={true}
            rcsConfig={{
              contextType: ed.settings.canvas_rce_user_context.type,
              contextId: ed.settings.canvas_rce_user_context.id,
              origin: originFromHost(contentProps.host),
              headers: headerFor(contentProps.jwt),
            }}
            userLocale={Bridge.userLocale}
            mountNode={instuiPopupMountNode}
            open={true}
            liveRegion={() => document.getElementById('flash_screenreader_holder')}
            onStartUpload={fileProps => handleStartUpload(fileProps)}
            onUploadComplete={(err, data) =>
              handleUpload(err, data, contentProps.mediaUploadComplete, uploadBookmark)
            }
            onDismiss={handleDismiss}
            tabs={{record: true, upload: true}}
            uploadMediaTranslations={Bridge.uploadMediaTranslations}
            media_links_use_attachment_id={RCEGlobals.getFeatures().media_links_use_attachment_id}
          />
        )}
      </StoreProvider>,
      container
    )
  })
}
