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
import {svgSettings as svgSettingsReducer, defaultState} from '../reducers/svgSettings'
import {BTN_AND_ICON_ATTRIBUTE, BTN_AND_ICON_DOWNLOAD_URL_ATTR} from '../registerEditToolbar'

const TYPE = 'image/svg+xml'

export const statuses = {
  ERROR: 'error',
  LOADING: 'loading',
  IDLE: 'idle'
}

export function useSvgSettings(editor, editing) {
  const [settings, dispatch] = useReducer(svgSettingsReducer, defaultState)
  const [status, setStatus] = useState(statuses.IDLE)

  useEffect(() => {
    const getImageNode = editor => {
      const selectedNode = editor.selection.getNode()

      // No selection made, return
      if (!selectedNode) return

      // The button and icon image is selected. return it
      if (selectedNode.getAttribute(BTN_AND_ICON_ATTRIBUTE)) return selectedNode

      // The button and icon image element is not selected, but it's possible
      // an element wrapping it is. Look for a button and icon image in the
      // selection's children
      const buttonAndIcon = selectedNode.querySelector(`img[${BTN_AND_ICON_ATTRIBUTE}="true"]`)

      // Still not button and icon found in the selection's children. Return
      if (!buttonAndIcon) return

      // Button and icon found in the selections children. Return it and set the
      // editor's selection to it as well
      editor.selection.select(buttonAndIcon)
      return buttonAndIcon
    }

    const fetchSvgSettings = async () => {
      try {
        setStatus(statuses.LOADING)

        const urlFromNode = getImageNode(editor)?.getAttribute(BTN_AND_ICON_DOWNLOAD_URL_ATTR)

        let downloadURL
        try {
          downloadURL = new URL(urlFromNode)
        } catch (error) {
          // The URL was likely relative. This happens after course
          // content goes through a course copy or other content migration.
          // Add the domain to the URL from the JS ENV.
          downloadURL = new URL(`${ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN}${urlFromNode}`)
        }

        // Adding the Course ID to the request causes Canvas to follow the chain
        // of files that were uploaded and "replaced" previous versions of the file.
        downloadURL.searchParams.append('replacement_chain_context_type', 'course')
        downloadURL.searchParams.append('replacement_chain_context_id', ENV.COURSE_ID)

        // Prevent the browser from using an old cached SVGs
        downloadURL.searchParams.append('ts', Date.now())

        // Parse SVG. If no SVG found, return defaults
        const svg = await svgFromUrl(downloadURL.toString())
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
