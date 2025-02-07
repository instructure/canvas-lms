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

import type {Editor} from 'tinymce'

// Common interfaces used across RCE components
export interface RCEWrapperInterface {
  id: string
  tinymce?: any
  mceInstance?: () => any
  insertCode?: (code: string) => void
  replaceCode?: (code: string) => void
  getContentSelection?: () => string
  getContent?: () => string
}

// Re-export the props type to avoid circular dependencies
export type {RCEWrapperProps} from './RCEWrapperProps'

export type AlertVariant = 'info' | 'warning' | 'error' | 'success'

export type AlertMessage = {
  id: number
  text: string
  variant: AlertVariant
}

export type RCETrayProps = {
  canUploadFiles: boolean
  contextId: string
  contextType: string
  host?: string
  jwt?: string
  containingContext?: {
    contextType: string
    contextId: string
    userId: string
  }
  filesTabDisabled?: boolean
  refreshToken?: () => void
  source?: {
    fetchImages: () => void
  }
  themeUrl?: string
}

/**
 * Subset of TinyMCE used by the ExternalTools dialog. Used to document the subset of the API that we use so
 * it's easier to test.
 */
export interface ExternalToolsEditor {
  id: string
  selection?: {
    getContent(): string
  }
  getContent(): string
  focus(): void
  editorContainer: HTMLElement
  $: Editor['$']
  ui: Editor['ui']
}

export interface ExternalToolData {
  id: string | number
  on_by_default?: boolean | null
  favorite?: boolean | null
}

// Extend Document interface to include webkit-specific fullscreen properties
declare global {
  interface Document {
    fullscreenElement?: HTMLElement | null
    webkitExitFullscreen(): Promise<void>
    webkitFullscreenElement?: HTMLElement | null
    webkitFullscreenEnabled?: boolean
  }
  interface HTMLDivElement {
    webkitRequestFullscreen(): Promise<void>
  }
}
