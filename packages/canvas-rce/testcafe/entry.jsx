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

// import React from 'react'
// import ReactDOM from 'react-dom'

import '@instructure/canvas-theme'

import {renderIntoDiv} from '../src'
import {enhanceUserContent} from '../src/enhance-user-content'

const content = document.getElementById('content')
if (content) {
  renderIntoDiv(content, {
    textareaId: 'textarea',
    editorOptions: () => {
      return {
        plugins: [
          'autolink',
          'media',
          'paste',
          'table',
          'link',
          'image',
          'instructure_upload_image',
          'directionality',
          'lists',
          'wordcount',
          'instructure-ui-icons',
          'instructure_equation',
          'instructure-embeds',
          'instructure_condensed_buttons',
          'instructure_documents',
          'instructure_equation',
          'instructure_media_embed',
          'instructure_image',
          'instructure_rce_external_tools',
          'instructure_record',
          'instructure_links',
          'instructure_html_view',
        ],
        menubar: true,
        screenReaderOnly: false,
      }
    },
    trayProps: {
      contextType: 'course',
      contextId: '17',
      containingContext: {type: 'course', contextId: '17', userId: '3', contextType: 'course'},
      canUploadFiles: true,
      host: 'someOtherHost',
      jwt: 'someJWT',
      liveRegion: () => {},
      screenReaderOnly: false,
    },
  })
} else {
  const user_content = document.getElementById('enhance_me')
  if (user_content) {
    enhanceUserContent(user_content)
  }
}
