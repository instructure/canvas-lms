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

import {useState, useEffect} from 'react'

/**
 * Custom React hook to dynamically get the width of the global navigation toggle button.
 * It observes the button for attribute changes (which might indicate a width change)
 * and returns its current width as a CSS-compatible string (e.g., '50px').
 *
 * @returns {string} The computed width of the global navigation button, or '0px' if not found.
 */
export default function useGlobalNavWidth(): string {
  const [globalNavWidth, setGlobalNavWidth] = useState<string>('0px')
  const globalNavToggleButton = document.getElementById('primaryNavToggle')

  useEffect(() => {
    if (!globalNavToggleButton) return

    setGlobalNavWidth(`${globalNavToggleButton?.getBoundingClientRect().width}px`)

    // Watch for attribute changes on the button.
    const observer = new MutationObserver(() => {
      setGlobalNavWidth(`${globalNavToggleButton?.getBoundingClientRect().width}px`)
    })

    // Start observing the button for attribute changes
    observer.observe(globalNavToggleButton, {attributes: true})

    return () => observer.disconnect()
  }, [globalNavToggleButton])

  return globalNavWidth
}
