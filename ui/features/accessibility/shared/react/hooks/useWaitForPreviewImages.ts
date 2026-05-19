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

import {useEffect} from 'react'
import {PreviewResponse} from '../types'

/**
 * Hook that waits for all images in the preview content to load before calling onLoaded.
 * This is specifically designed for the Preview component to delay hiding the loading spinner
 * until all images in the accessibility preview content are ready.
 */
export const useWaitForPreviewImages = (
  previewRef: React.RefObject<HTMLElement>,
  contentResponse: PreviewResponse | null,
  onLoaded: () => void,
) => {
  useEffect(() => {
    if (!contentResponse?.content) {
      return
    }

    if (!previewRef.current) {
      onLoaded()
      return
    }

    const images = previewRef.current.querySelectorAll('img')
    if (images.length === 0) {
      onLoaded()
      return
    }

    let loadedCount = 0
    let isCancelled = false
    const totalImages = images.length

    const checkAllLoaded = () => {
      if (isCancelled) return
      loadedCount++
      if (loadedCount === totalImages) {
        onLoaded()
      }
    }

    images.forEach(img => {
      if (img.complete) {
        checkAllLoaded()
      } else {
        img.addEventListener('load', checkAllLoaded, {once: true})
        img.addEventListener('error', checkAllLoaded, {once: true})
      }
    })

    return () => {
      isCancelled = true
      images.forEach(img => {
        img.removeEventListener('load', checkAllLoaded)
        img.removeEventListener('error', checkAllLoaded)
      })
    }
  }, [contentResponse, onLoaded, previewRef])
}
