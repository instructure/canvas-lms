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
import createRoot from 'react-dom/client'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import {useState, useEffect} from 'react'

const MediaPlayer = ({elementId, mediaId}) => {
  const [rootRef, setRootRef] = useState(null)

  useEffect(() => {
    const handler = setTimeout(() => {
      const el = document.getElementById(elementId)

      if (el) {
        const root = createRoot.createRoot(el)
        setRootRef(root)
      }
    }, 500)

    return () => {
      clearTimeout(handler)
    }
  }, [elementId])

  if (rootRef) {
    rootRef.render(
      <CanvasStudioPlayer media_id={mediaId} explicitSize={{width: 550, height: 400}} />,
    )
  }
}

export default MediaPlayer
