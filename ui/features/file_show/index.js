/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import {loadDocPreview} from '@instructure/canvas-rce/es/enhance-user-content/doc_previews'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import ready from '@instructure/ready'

const previewDefaults = {
  height: '100%',
  scribdParams: {
    auto_size: true,
  },
}

ready(() => {
  const previewDiv = $('#doc_preview')
  previewDiv.fillWindowWithMe()
  loadDocPreview(previewDiv[0], $.merge(previewDefaults, previewDiv.data()))
})
