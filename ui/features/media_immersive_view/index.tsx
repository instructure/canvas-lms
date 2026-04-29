/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render} from '@canvas/react'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {MediaInfo} from '@canvas/canvas-studio-player/react/types'
import './index.css'

import {ImmersiveView} from './ImmersiveView'

declare const ENV: GlobalEnv & {
  media_object: MediaInfo
  attachment_id?: string
  attachment?: boolean
}

render(
  <ImmersiveView
    id={ENV.media_object?.media_id}
    title={ENV.media_object?.title}
    attachmentId={ENV.attachment_id}
    isAttachment={ENV.attachment}
  />,
  document.getElementById('immersive_view_container'),
)
