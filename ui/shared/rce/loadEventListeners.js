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
import initializeExternalTools from '@canvas/tinymce-external-tools'
import INST from 'browser-sniffer'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('loadEventListeners')

export default function loadEventListeners(callbacks = {}) {
  const validCallbacks = ['equationCB', 'equellaCB', 'externalToolCB']

  validCallbacks.forEach(cbName => {
    if (callbacks[cbName] === undefined) {
      callbacks[cbName] = function () {
        /* no-op */
      }
    }
  })

  document.addEventListener('tinyRCE/initEquation', ({detail}) => {
    import('./backbone/views/EquationEditorView')
      .then(({default: EquationEditorView}) => {
        const view = new EquationEditorView(detail.ed)
        callbacks.equationCB(view)
      })
      .catch(showFlashError(I18n.t('Something went wrong loading the equation editor')))
  })

  document.addEventListener('tinyRCE/initEquella', e => {
    import('@canvas/tinymce-equella')
      .then(({default: initializeEquella}) => {
        initializeEquella(e.detail.ed)
        callbacks.equellaCB()
      })
      .catch(showFlashError(I18n.t('Something went wrong loading Equella')))
  })

  document.addEventListener('tinyRCE/initExternalTools', e => {
    initializeExternalTools.init(e.detail.ed, e.detail.url, INST)
    callbacks.externalToolCB()
  })
}
