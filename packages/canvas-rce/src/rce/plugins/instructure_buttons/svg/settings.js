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
import RceApiSource from '../../../../rcs/api'

const TYPE = 'image/svg+xml'

export const statuses = {
  ERROR: 'error',
  LOADING: 'loading',
  IDLE: 'idle'
}

const getImageNode = (editor, editing) => {
  // If the user is creating a button rather then editing, no sense trying
  // to get an existing SVG URL
  if (!editing) return

  const selectedNode = editor?.selection?.getNode()

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

export function useSvgSettings(editor, editing, rcsConfig) {
  const [settings, dispatch] = useReducer(svgSettingsReducer, defaultState)
  const [status, setStatus] = useState(statuses.IDLE)

  const buildFilesUrl = (fileId, host) => {
    // http://canvas.docker/files/2169/download?download_frd=1&amp;buttons_and_icons=1

    const downloadURL = new URL(`${host}/files/${fileId}/download`)

    // Adding the Course ID to the request causes Canvas to follow the chain
    // of files that were uploaded and "replaced" previous versions of the file.
    downloadURL.searchParams.append('replacement_chain_context_type', 'course')
    downloadURL.searchParams.append('replacement_chain_context_id', rcsConfig.contextId)

    // Prevent the browser from using an old cached SVGs
    downloadURL.searchParams.append('ts', Date.now())

    // Yes, we want do download for real dude
    downloadURL.searchParams.append('download_frd', 1)

    return downloadURL.toString()
  }

  const urlFromNode = getImageNode(editor, editing)?.getAttribute(BTN_AND_ICON_DOWNLOAD_URL_ATTR)

  useEffect(() => {
    const fetchSvgSettings = async () => {
      if (!urlFromNode) return

      try {
        setStatus(statuses.LOADING)

        // Parse out the file ID from something like
        // /courses/1/files/3/preview?...
        const fileId = urlFromNode.split('files/')[1]?.split('/')[0]
        const downloadUrl = buildFilesUrl(fileId, rcsConfig.canvasUrl)

        // Parse SVG. If no SVG found, return defaults
        const svg = await svgFromUrl(downloadUrl)
        if (!svg) return

        // Parse metadata. If no metadata found, return defaults
        const metadata = svg.querySelector('metadata')?.innerHTML
        if (!metadata) return

        const rcs = new RceApiSource(rcsConfig)

        const fileData = await rcs.getFile(fileId, {
          replacement_chain_context_type: rcsConfig.contextType,
          replacement_chain_context_id: rcsConfig.contextId
        })
        const fileName = fileData.name.replace(/\.[^\.]+$/, '')

        const metadataJson = JSON.parse(metadata)
        metadataJson.name = fileName
        metadataJson.originalName = fileName

        // settings found, return parsed results
        dispatch(metadataJson)
        setStatus(statuses.IDLE)
      } catch (e) {
        setStatus(statuses.ERROR)
      }
    }

    // If we are editing rather than creating, fetch existing settings
    if (editing) fetchSvgSettings()
  }, [editor, editing, urlFromNode, rcsConfig])

  return [settings, status, dispatch]
}

export async function svgFromUrl(url) {
  const response = await fetch(url)

  const data = await response.text()
  return new DOMParser().parseFromString(data, TYPE)
}
