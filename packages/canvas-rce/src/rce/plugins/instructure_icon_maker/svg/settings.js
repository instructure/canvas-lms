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
import {ICON_MAKER_ATTRIBUTE, ICON_MAKER_DOWNLOAD_URL_ATTR, SVG_XML_TYPE} from './constants'
import {modes} from '../reducers/imageSection'
import iconsLabels from '../utils/iconsLabels'

export const statuses = {
  ERROR: 'error',
  LOADING: 'loading',
  IDLE: 'idle'
}

const getImageNode = (editor, editing) => {
  // If the user is creating an icon rather then editing, no sense trying
  // to get an existing SVG URL
  if (!editing) return

  const selectedNode = editor?.selection?.getNode()

  // No selection made, return
  if (!selectedNode) return

  // The icon maker image is selected. return it
  if (selectedNode.getAttribute(ICON_MAKER_ATTRIBUTE)) return selectedNode

  // The icon maker image element is not selected, but it's possible
  // an element wrapping it is. Look for a icon maker image in the
  // selection's children
  const iconMaker = selectedNode.querySelector(`img[${ICON_MAKER_ATTRIBUTE}="true"]`)

  // Icon maker still not found in the selection's children. Return
  if (!iconMaker) return

  // Icon maker found in the selections children. Return it and set the
  // editor's selection to it as well
  editor.selection.select(iconMaker)
  return iconMaker
}

const buildMetadataUrl = (fileId, rcsConfig) => {
  // http://canvas.docker/api/v1/files/2169/icon_metadata

  const downloadURL = new URL(`${rcsConfig.canvasUrl}/api/v1/files/${fileId}/icon_metadata`)
  return downloadURL.toString()
}

export function useSvgSettings(editor, editing, rcsConfig) {
  const [settings, dispatch] = useReducer(svgSettingsReducer, defaultState)
  const [status, setStatus] = useState(statuses.IDLE)

  const imgNode = getImageNode(editor, editing)
  const urlFromNode = imgNode?.getAttribute(ICON_MAKER_DOWNLOAD_URL_ATTR)
  const altText = imgNode?.getAttribute('alt')

  const customStyle = imgNode?.getAttribute('style')
  const customWidth = imgNode?.getAttribute('width')
  const customHeight = imgNode?.getAttribute('height')

  useEffect(() => {
    const fetchSvgSettings = async () => {
      if (!urlFromNode) return

      try {
        setStatus(statuses.LOADING)

        // Parse out the file ID from something like
        // /courses/1/files/3/preview?...
        const fileId = urlFromNode.split('files/')[1]?.split('/')[0]
        const downloadUrl = buildMetadataUrl(fileId, rcsConfig)

        // Download icon metadata. If no metadata found, return defaults
        const response = await fetch(downloadUrl)
        const metadata = await response.text()
        if (!metadata) return

        const metadataJson = JSON.parse(metadata)
        const fileName = metadataJson.name.replace(/\.[^\.]+$/, '')
        metadataJson.name = fileName
        metadataJson.originalName = fileName

        if (altText === '') {
          metadataJson.isDecorative = true
        } else if (altText) {
          metadataJson.alt = altText
        }

        // Include external details on metadata
        if (customWidth && customHeight) {
          metadataJson.externalWidth = customWidth
          metadataJson.externalHeight = customHeight
        }

        if (customStyle) {
          metadataJson.externalStyle = customStyle
        }

        processMetadataForBackwardCompatibility(metadataJson)

        // settings found, return parsed results
        dispatch(metadataJson)
        setStatus(statuses.IDLE)
      } catch (e) {
        setStatus(statuses.ERROR)
      }
    }

    // If we are editing rather than creating, fetch existing settings
    if (editing) fetchSvgSettings()
  }, [editor, editing, urlFromNode, rcsConfig, altText, customWidth, customHeight, customStyle])

  return [settings, status, dispatch]
}

function processMetadataForBackwardCompatibility(metadataJson) {
  const icon = metadataJson?.imageSettings?.icon
  const mode = metadataJson?.imageSettings?.mode
  if (mode === modes.singleColorImages.type && typeof icon === 'object') {
    const foundIconId = iconsLabels[icon.label]
    if (foundIconId) {
      metadataJson.imageSettings.icon = foundIconId
    } else {
      metadataJson.imageSettings = null
    }
  }
}
