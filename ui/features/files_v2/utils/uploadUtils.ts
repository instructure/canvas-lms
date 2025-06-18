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

import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {FileOptionsResults} from '../react/components/FilesHeader/UploadButton/FileOptions'
import {BBFolderWrapper} from './fileFolderWrappers'

export const queueOptionsCollectionUploads = (
  contextId: string | number,
  contextType: string,
  fileOptions?: FileOptionsResults | null,
  onClose?: () => void,
) => {
  if (!fileOptions) return
  if (
    fileOptions.zipOptions.length === 0 &&
    fileOptions.nameCollisions.length === 0 &&
    FileOptionsCollection.hasNewOptions()
  ) {
    if (fileOptions.resolvedNames.length > 0) {
      FileOptionsCollection.queueUploads(contextId, contextType)
    }
    onClose?.()
  }
}

export const startUpload = (
  folder: BBFolderWrapper,
  contextId: string | number,
  contextType: string,
  onClose: (() => void) | undefined,
  files: ArrayLike<DataTransferItem | globalThis.File>,
) => {
  FileOptionsCollection.setFolder(folder)
  FileOptionsCollection.setUploadOptions({
    alwaysRename: false,
    alwaysUploadZips: false,
    errorOnDuplicate: true,
  })
  FileOptionsCollection.setOptionsFromFiles(files, true)
  const fileOptions = FileOptionsCollection.getState()
  queueOptionsCollectionUploads(contextId, contextType, fileOptions, onClose)
  return fileOptions
}
