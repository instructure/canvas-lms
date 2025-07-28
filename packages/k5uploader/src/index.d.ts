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

declare module '@instructure/k5uploader' {
  interface K5UploaderOptions {
    kaltura_session: string
    allowedMediaTypes: string[]
  }

  interface K5UploaderInstance {
    destroy(): void
    uploadFile(file: File): void
    onSessionLoaded(data: any): void
    loadUiConf(): void
    onUiConfComplete(result: any): void
    onUploadSuccess(result: any): void
    onUploadError(result: any): void
    onEntrySuccess(data: any): void
    onEntryFail(data: any): void
    onUiConfError(result: any): void
  }

  class K5Uploader {
    constructor(options: K5UploaderOptions)

    destroy(): void
    uploadFile(file: File): void
    onSessionLoaded(data: any): void
    loadUiConf(): void
    onUiConfComplete(result: any): void
    onUploadSuccess(result: any): void
    onUploadError(result: any): void
    onEntrySuccess(data: any): void
    onEntryFail(data: any): void
    onUiConfError(result: any): void
  }

  export default K5Uploader
}
