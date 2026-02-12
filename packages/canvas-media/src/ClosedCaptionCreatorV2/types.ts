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
 * Upload/Processing states for caption files
 */
export type CaptionUploadStatus = 'processing' | 'failed' | 'uploaded'

/**
 * Creation mode for new captions
 */
export type CaptionCreationMode = 'manual' | 'auto'

/**
 * Subtitle file information
 */
export interface SubtitleFile {
  name: string
  url?: string // Download URL when uploaded
}

/**
 * Subtitle/Caption track
 */
export interface Subtitle {
  locale: string // Language code (e.g., 'en', 'fr', 'es')
  inherited?: boolean // Whether caption is inherited from parent course
  file: SubtitleFile
  isNew?: boolean // Whether this is a newly added caption
  status?: CaptionUploadStatus // Upload state (processing, failed, or uploaded)
  errorMessage?: string // Error message if upload failed
}

/**
 * Language option for selection dropdown
 */
export interface LanguageOption {
  id: string // Language code
  label: string // Display name
}

/**
 * File validation result
 */
export interface ValidationResult {
  valid: boolean
  error?: string
}

/**
 * Request headers for API calls
 * Typically includes Authorization header for authenticated requests
 */
export interface RequestHeaders {
  /** Authorization header (e.g., 'Bearer <token>') */
  Authorization?: string
  /** Allow additional string headers */
  [key: string]: string | undefined
}

/**
 * Configuration for caption upload/delete operations
 * Provide either mediaObjectId or attachmentId (validated at runtime)
 */
export interface CaptionUploadConfig {
  /** Media object ID - provide either this or attachmentId */
  mediaObjectId?: string
  /** Attachment ID - provide either this or mediaObjectId */
  attachmentId?: string
  /** RCS origin URL */
  origin?: string
  /** Request headers (typically includes Authorization: 'Bearer <token>') */
  headers?: RequestHeaders
  /** Maximum file size in bytes */
  maxBytes?: number
}
