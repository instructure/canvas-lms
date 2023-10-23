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

import {useEffect, useCallback} from 'react'

const useHoverIntent = (element: Element | null, onIntent: () => void, delay = 200) => {
  const handleMouseOver = useCallback(() => {
    const timer = setTimeout(() => {
      onIntent()
    }, delay)

    const handleMouseOut = () => clearTimeout(timer)

    if (element) {
      element.addEventListener('mouseleave', handleMouseOut)
    }

    return () => {
      if (element) {
        element.removeEventListener('mouseleave', handleMouseOut)
      }
    }
  }, [element, onIntent, delay])

  useEffect(() => {
    if (element) {
      element.addEventListener('mouseenter', handleMouseOver)
    }

    return () => {
      if (element) {
        element.removeEventListener('mouseenter', handleMouseOver)
      }
    }
  }, [element, handleMouseOver])
}

export default useHoverIntent
