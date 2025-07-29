/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

// Uses stuff from lti/model which is new models with zod stuff. We should try
// not to import the other way around.
import {AssetProcessorWindowSettings} from '@canvas/lti/model/AssetProcessor'
import {ContentItemIframeDimensions} from './helpers'

export type AssetProcessorContentItemReport = {
  url?: string
  custom?: Record<string, string>
}

export type AssetProcessorContentItem = {
  type: 'ltiAssetProcessor' | 'ltiAssetProcessorContribution'
  // Not sure where this comes from. Cargo cult from ResourceLinkContentItem, needed by usages of ContentItem.
  // presumably Canvas is adding it somewhere
  errors?: Record<string, string>
} & AssetProcessorCommonFields

// Part of the the JSON sent to the API when saving (creating/editing) assignments
// Should match up with ruby app/models/lti/asset_processor.rb#build_for_assignment
export type AssetProcessorContentItemDto = {
  context_external_tool_id: number | string
} & AssetProcessorCommonFields

export type AssetProcessorCommonFields = {
  // Fully qualified url of the asset processor settings. If absent, the base LTI URL of the tool must be used for launch.
  url?: string
  // Plain text to use as the display name for the processor.
  title?: string
  // Plain text description of the processor to be displayed to all users who can access the item.
  text?: string
  // Fully qualified URL, height, and width of an icon image to be placed with the file.
  icon?: {
    url: string
    width?: number
    height?: number
  }
  // Fully qualified URL, height, and width of a thumbnail image to be made a hyperlink.
  thumbnail?: {
    url: string
    width?: number
    height?: number
  }
  // The window property indicates how to open the asset processor settings in a new window/tab.
  window?: AssetProcessorWindowSettings
  // The iframe property indicates the asset processor settings can be embedded using an iframe.
  iframe?: ContentItemIframeDimensions
  // A map of key/value custom parameters.
  custom?: Record<string, string>
  // A report object provides configuration around the reports that are passed back.
  report?: AssetProcessorContentItemReport
}

export function assetProcessorContentItemToDto(
  contentItem: AssetProcessorContentItem,
  toolId: number | string,
): AssetProcessorContentItemDto {
  const {type, errors, ...commonFields} = contentItem
  return {context_external_tool_id: toolId, ...commonFields}
}
