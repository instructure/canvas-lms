// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import tinymce, {Editor} from 'tinymce'
import bridge from '../../../bridge'
import configureStore from '../../../sidebar/store/configureStore'
import {get as getSession} from '../../../sidebar/actions/session'
import {uploadToMediaFolder} from '../../../sidebar/actions/upload'
import doFileUpload, {DoFileUploadResult} from '../shared/Upload/doFileUpload'
import formatMessage from '../../../format-message'
import {isAudioOrVideo, isImage} from '../shared/fileTypeUtils'
import {showFlashAlert} from '../../../common/FlashAlert'
import {
  isMicrosoftWordContentInEvent,
  RCEClipOrDragEvent,
  TinyClipboardEvent,
  TinyDragEvent,
} from '../shared/EventUtils'
import RCEWrapper from '../../RCEWrapper'

// assume that if there are multiple RCEs on the page,
// they all talk to the same canvas
const config = {
  store: null as any,
  session: null as any, // null: we haven't gotten it yet, false: we don't need it
  sessionPromise: null as any,
}

// when UploadFile renders
// <StoreProvider {...trayProps}>
//  {contentProps => {
//     return (
//       <UploadFileModal
// The StoreProvider function calls configureStore which creates a new store
// (We don't seem to have a way to grab an existing store)
// So the configureStore and getSession logic gets repeated here for the
// automatic file upload when pasting or dropping a file on the RCE
function initStore(initProps) {
  if (config.store === null) {
    config.store = configureStore(initProps)
  }
  if (config.session === null) {
    if (initProps.host && initProps.jwt) {
      config.sessionPromise = getSession(config.store.dispatch, config.store.getState)
        .then(() => {
          config.session = config.store.getState().session
        })
        .catch(_err => {
          // eslint-disable-next-line no-console
          console.error('The Paste plugin failed to get canvas session data.')
        })
    } else {
      // RCEWrapper will keep us from getting here, but we really should do something anyway.
      config.session = false
      config.sessionPromise = Promise.resolve()
    }
  }
  return config.store
}

tinymce.PluginManager.add(
  'instructure_paste',
  function (editor: Editor & {rceWrapper?: RCEWrapper}) {
    const store = initStore(bridge.trayProps.get(editor))

    /**
     * Starts the file upload (and insertion) process for the given file.
     *
     * If usage rights are required, a dialog will be displayed.
     *
     * @returns a promise that resolves when the user has made their choice about uploading the file
     */
    async function requestFileInsertion(file: File): Promise<DoFileUploadResult> {
      // it's very doubtful that we won't have retrieved the session data yet,
      // since it takes a while for the RCE to initialize, but if we haven't
      // wait until we do to carry on and finish pasting.
      await config.sessionPromise

      if (config.session === null) {
        // we failed to get the session and don't know if usage rights are required in this course|group
        // In all probability, the file upload will fail too, but I feel like we have to do something here.
        showFlashAlert({
          message: formatMessage(
            'If Usage Rights are required, the file will not publish until enabled in the Files page.'
          ),
          type: 'info',
        } as any)
      }

      // even though usage rights might be required by the course, canvas has no place
      // on the user to store it. Only Group and Course.
      const requiresUsageRights =
        config.session.usageRightsRequired &&
        /course|group/.test(bridge.trayProps.get(editor).contextType)

      if (requiresUsageRights) {
        return doFileUpload(editor, document, {
          accept: file.type,
          panels: ['COMPUTER'],
          preselectedFile: file,
        }).closedPromise
      } else {
        const fileMetaProps = {
          altText: file.name,
          contentType: file.type,
          displayAs: 'embed',
          isDecorativeImage: false,
          name: file.name,
          parentFolderId: 'media',
          size: file.size,
          domObject: file,
        }

        let tabContext = 'documents'

        if (isImage(file.type)) {
          tabContext = 'images'
        } else if (isAudioOrVideo(file.type)) {
          tabContext = 'media'
        }

        store.dispatch(uploadToMediaFolder(tabContext, fileMetaProps))

        return 'submitted'
      }
    }

    async function handlePasteOrDrop(event: RCEClipOrDragEvent) {
      const isPaste = event.type === 'paste'
      const dataTransfer = isPaste
        ? (event as TinyClipboardEvent).clipboardData
        : (event as TinyDragEvent).dataTransfer
      const files = Array.from(dataTransfer?.files || [])
      const types = dataTransfer?.types || []

      const isAudioVideoDisabled = bridge.activeEditor()?.props?.instRecordDisabled

      // delegate to tiny if there aren't any files to handle
      if (!types.includes('Files')) return

      // delegate to tiny if there is Microsoft Word content, because it may contain an image
      // rendering of the content and we don't want to incorrectly paste the image
      // instead of the actual rich content, which TinyMCE has special handing for
      if (isMicrosoftWordContentInEvent(event)) return

      // we're pasting file(s), prevent the default tinymce pasting behavior
      event.preventDefault()

      // Ensure the editor has focus, because downstream code requires that it does, and drag-n-drop
      // events can be started when the editor doesn't have focus.
      if (!editor.hasFocus()) editor.rceWrapper?.focus()

      // Checking if we've encountered an issue with file processing for paste events in the browser
      // Specifically implementing due to this bug in Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=1699743
      // However, there could be other issues that cause this condition so it's a nice safety net regardless
      if (isPaste && files.some(file => file.size === 0)) {
        showFlashAlert({
          message: formatMessage(
            'One or more files failed to paste. Please try uploading or dragging and dropping files.'
          ),
          type: 'error',
        })
        return
      }

      for (const file of files) {
        if (isAudioVideoDisabled && isAudioOrVideo(file.type)) {
          // Skip audio and video files when disabled
          continue
        }

        // This will finish once the dialog is closed, if one was created, putting this in a loop allows us
        // to show a dialog for each file without them conflicting.
        // eslint-disable-next-line no-await-in-loop
        await requestFileInsertion(file)
      }
    }

    editor.on('paste', handlePasteOrDrop)
    editor.on('drop', handlePasteOrDrop)
  }
)
