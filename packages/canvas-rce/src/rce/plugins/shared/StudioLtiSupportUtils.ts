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

/**
 * Interface for content item's 'custom' field, specifically for what is expected to come from Studio
 *
 * Used to determine whether or not Studio embedded media should be resizable, and whether or not we
 * present controls for the user to modify the embedded media.
 */
export interface StudioContentItemCustomJson {
  source: 'studio'
  resizable?: boolean
  enableMediaOptions?: boolean
}

interface StudioMediaOptionsAttributes {
  'data-studio-resizable': boolean
  'data-studio-tray-enabled': boolean
  'data-studio-convertible-to-link': boolean
}

export function isStudioContentItemCustomJson(input: any): input is StudioContentItemCustomJson {
  return typeof input === 'object' && input.source === 'studio'
}

export function studioAttributesFrom(
  customJson: StudioContentItemCustomJson
): StudioMediaOptionsAttributes {
  return {
    'data-studio-resizable': customJson.resizable ?? false,
    'data-studio-tray-enabled': customJson.enableMediaOptions ?? false,
    'data-studio-convertible-to-link': true,
  }
}
