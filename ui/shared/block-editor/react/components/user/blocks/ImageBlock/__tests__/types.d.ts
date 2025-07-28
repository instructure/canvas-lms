/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export interface MockFile {
  id: number
  filename: string
  thumbnail_url: string
  display_name: string
  href: string
  download_url: string
  content_type: string
  published: boolean
  hidden_to_user: boolean
  locked_for_user: boolean
  unlock_at: string | null
  lock_at: string | null
  date: string
  uuid: string
}

export interface MockImageData extends ImageData {
  hasMore: boolean
  isLoading: boolean
  error: string
  files: MockFile[]
}

export interface MockTrayProps {
  canvasOrigin: string
  canUploadFiles: boolean
  containingContext: {
    contextType: string
    contextId: string
    userId: string
  }
  contextType: string
  contextId: string
  filesTabDisabled: boolean
  host: string
  jwt: string
  refreshToken: () => void
  themeUrl: string
  source: {
    initializeCollection: () => void
    initializeUpload: () => void
    initializeFlickr: () => void
    initializeImages: () => void
    initializeDocuments: () => void
    initializeMedia: () => void
    fetchImages: jest.Mock
    getSession: jest.Mock
  }
  storeProps: Record<string, unknown>
  images: {
    user: MockImageData
    course: MockImageData
    group: MockImageData
  }
}

export interface MockNode {
  props: Partial<ImageBlockProps>
  actions: {
    setProp: (callback: (props: Partial<ImageBlockProps>) => void) => void
  }
  node: {
    dom: HTMLElement
  }
  domnode: HTMLElement
}
