/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useState, useEffect, useReducer} from 'react'
import {DEFAULT_SETTINGS} from '../svg/constants'

const TYPE = 'image/svg+xml'

export const statuses = {
  ERROR: 'error',
  LOADING: 'loading',
  IDLE: 'idle'
}

export function useSvgSettings(editor, editing) {
  const [settings, dispatch] = useReducer(
    (state, changes) => ({...state, ...changes}),
    DEFAULT_SETTINGS
  )
  const [status, setStatus] = useState(statuses.IDLE)

  useEffect(() => {
    const fetchSvgSettings = async () => {
      try {
        setStatus(statuses.LOADING)

        // Parse SVG. If no SVG found, return defaults
        const svg = await svgFromUrl(editor.selection.getNode()?.src)
        if (!svg) return

        // Parse metadata. If no metadata found, return defaults
        const metadata = svg.querySelector('metadata')?.innerHTML
        if (!metadata) return

        // settings found, return parsed results
        dispatch(JSON.parse(metadata))
        setStatus(statuses.IDLE)
      } catch (e) {
        setStatus(statuses.ERROR)
      }
    }

    // If we are editing rather than creating, fetch existing settings
    if (editing) fetchSvgSettings()
  }, [editor, editing])

  return [settings, status, dispatch]
}

export async function svgFromUrl(url) {
  const response = await fetch(url)
  const data = await response.text()
  return new DOMParser().parseFromString(data, TYPE)
}
