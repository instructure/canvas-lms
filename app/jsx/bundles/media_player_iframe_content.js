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

import CanvasMediaPlayer from '../shared/media/CanvasMediaPlayer'
import React from 'react'
import ReactDOM from 'react-dom'

// get the media_id from something like `http://canvas.example.com/media_objects_iframe/m-48jGWTHdvcV5YPdZ9CKsqbtRzu1jURgu`
const media_id = window.location.pathname.split('media_objects_iframe/').pop()

ReactDOM.render(
  <CanvasMediaPlayer media_id={media_id} media_sources={ENV.media_sources} />,
  document.body.appendChild(document.createElement('div'))
)
