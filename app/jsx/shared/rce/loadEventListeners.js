/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
export default function loadEventListeners (callbacks = {}) {
  const validCallbacks = [
    'equationCB',
    'linksCB',
    'imagePickerCB',
    'equellaCB',
    'externalToolCB',
    'recordCB'
  ]

  validCallbacks.forEach((cbName) => {
    if (callbacks[cbName] === undefined) {
      callbacks[cbName] = function () { /* no-op*/ }
    }
  })

  document.addEventListener('tinyRCE/initEquation', ({detail}) => {
    require.ensure([], (require) => {
      const EquationEditorView = require('compiled/views/tinymce/EquationEditorView')
      const view = new EquationEditorView(detail.ed)
      callbacks.equationCB(view)
    }, 'initEquationAsyncChunk')
  })

  document.addEventListener('tinyRCE/initLinks', ({detail}) => {
    require.ensure([], (require) => {
      const Links = require('tinymce_plugins/instructure_links/links')
      Links.initEditor(detail.ed)
      Links.renderDialog(detail.ed)
      callbacks.linksCB()
    }, 'initLinksAsyncChunk')
  })

  document.addEventListener('tinyRCE/initImagePicker', (e) => {
    require.ensure([], (require) => {
      const InsertUpdateImageView = require('compiled/views/tinymce/InsertUpdateImageView')
      const view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode)
      callbacks.imagePickerCB(view)
    }, 'initImagePickerAsyncChunk')
  })

  document.addEventListener('tinyRCE/initEquella', (e) => {
    require.ensure([], (require) => {
      const initializeEquella = require('tinymce_plugins/instructure_equella/initializeEquella')
      initializeEquella(e.detail.ed)
      callbacks.equellaCB()
    }, 'initEquellaAsyncChunk')
  })

  document.addEventListener('tinyRCE/initExternalTools', (e) => {
    require.ensure([], (require) => {
      const initializeExternalTools = require('tinymce_plugins/instructure_external_tools/initializeExternalTools')
      const INST = require('INST')

      initializeExternalTools.init(e.detail.ed, e.detail.url, INST)
      callbacks.externalToolCB()
    }, 'initExternalToolsAsyncChunk')
  })

  document.addEventListener('tinyRCE/initRecord', (e) => {
    require.ensure([], (require) => {
      const mediaEditorLoader = require('tinymce_plugins/instructure_record/mediaEditorLoader')
      mediaEditorLoader.insertEditor(e.detail.ed)
      callbacks.recordCB()
    }, 'initRecordAsyncChunk')
  })
}
