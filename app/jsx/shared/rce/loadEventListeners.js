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

import EquationEditorView from 'compiled/views/tinymce/EquationEditorView'
import Links from 'tinymce_plugins/instructure_links/links'
import InsertUpdateImageView from 'compiled/views/tinymce/InsertUpdateImageView'
import initializeEquella from 'tinymce_plugins/instructure_equella/initializeEquella'
import initializeExternalTools from 'tinymce_plugins/instructure_external_tools/initializeExternalTools'
import mediaEditorLoader from 'tinymce_plugins/instructure_record/mediaEditorLoader'
import INST from 'INST'

  function loadEventListeners (callbacks={}) {
    const validCallbacks = [
      'equationCB',
      'linksCB',
      "imagePickerCB",
      "equellaCB",
      "externalToolCB",
      "recordCB"
    ]

    validCallbacks.forEach( (cbName) => {
      if (callbacks[cbName] === undefined) {
        callbacks[cbName] = function(){ /* no-op*/ }
      }
    })

    document.addEventListener('tinyRCE/initEquation', ({detail}) => {
      const view = new EquationEditorView(detail.ed)
      callbacks.equationCB(view)
    });

    document.addEventListener('tinyRCE/initLinks', ({detail}) => {
      Links.initEditor(detail.ed)
      Links.renderDialog(detail.ed)
      callbacks.linksCB()
    });

    document.addEventListener('tinyRCE/initImagePicker', function(e){
      let view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode);
      callbacks.imagePickerCB(view)
    });

    document.addEventListener('tinyRCE/initEquella', function(e) {
      initializeEquella(e.detail.ed)
      callbacks.equellaCB()
    });

    document.addEventListener('tinyRCE/initExternalTools', function(e) {
      initializeExternalTools.init(e.detail.ed, e.detail.url, INST)
      callbacks.externalToolCB()
    });

    document.addEventListener('tinyRCE/initRecord', function(e) {
      mediaEditorLoader.insertEditor(e.detail.ed)
      callbacks.recordCB()
    });
  }

export default loadEventListeners
