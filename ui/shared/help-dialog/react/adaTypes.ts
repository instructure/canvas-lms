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

/**
 * Type definitions for Ada Embed SDK
 *
 * Reference: https://docs.ada.cx/generative/chat/web/sdk-api-reference#type-signatures
 * Only includes types currently in use. Extend as needed for additional functionality.
 */

/**
 * Window information returned by getInfo()
 */
export type WindowInfo = {
  isChatOpen: boolean
  isDrawerOpen: boolean
  hasActiveChatter: boolean
  hasClosedChat: boolean
}

/**
 * Ada embed settings/configuration options
 */
export type AdaSettings = {
  handle?: string
  crossWindowPersistence?: boolean
  hideMask?: boolean
  metaFields?: Record<string, string | boolean | number>
  adaReadyCallback?: (params: {isRolledOut: boolean}) => void
  onAdaEmbedLoaded?: () => void
  toggleCallback?: (isDrawerOpen: boolean) => void
  [key: string]: any
}

/**
 * The adaEmbed global object
 */
export type AdaEmbed = {
  start: (config: AdaSettings) => Promise<void>
  getInfo: () => Promise<WindowInfo>
  toggle: () => Promise<void>
  stop?: () => Promise<void>
  subscribeEvent: (
    eventKey: string,
    callback: (data: object, context: {eventKey: string}) => void,
  ) => Promise<number>
}

/**
 * The AdaEmbed constructor (for non-lazy loading)
 */
export type AdaEmbedConstructor = {
  start: (config: AdaSettings) => Promise<void>
}
