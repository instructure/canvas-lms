/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {renderIntoDiv} from 'canvas-rce'
import canvasTheme from '@instructure/canvas-theme'

import {getInstance, setLocale} from './plugin'
import 'tinymce/plugins/image'

getInstance(instance => instance.setConfig({disableContrastCheck: false}))
const lang = (/lang=([^&]+)/.exec(window.location.search) || {})[1]
setLocale(lang || 'en')

canvasTheme.use()

function renderEditor(editorEl, textareaId) {
  renderIntoDiv(editorEl, {
    defaultContent: document.getElementById(textareaId).value,
    editorOptions: () => {
      return {
        height: '600px',
        plugins: 'link, image, textcolor, table, a11y_checker',
        menubar: true,
        toolbar: [
          'bold,italic,underline,|,link,image,|,forecolor,backcolor,|,alignleft,aligncenter,alignright,|,outdent,indent,|,bullist,numlist,|,fontsizeselect,formatselect,|,check_a11y',
        ],
      }
    },
    textareaId,
  })
}

renderEditor(document.getElementById('editor1'), 'textarea1')
renderEditor(document.getElementById('editor2'), 'textarea2')
