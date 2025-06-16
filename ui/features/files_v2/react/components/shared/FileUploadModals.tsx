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
import {type FileOptionsResults} from '../FilesHeader/UploadButton/FileOptions'
import ZipFileOptionsForm from '../FilesHeader/UploadButton/ZipFileOptionsForm'
import FileRenameForm from '../FilesHeader/UploadButton/FileRenameForm'
import {createPortal} from 'react-dom'

export const FileUploadModals = ({
  fileOptions,
  onResolved,
  onClose,
}: {
  fileOptions: FileOptionsResults | null
  onResolved: (fileOptions: FileOptionsResults) => void
  onClose: (fileOptions: FileOptionsResults) => void
}) => {
  const onZipOptionsResolved = (fileNameOptions: any) => {
    FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
    onResolved(FileOptionsCollection.getState())
  }

  const onNameConflictResolved = (fileNameOptions: any) => {
    FileOptionsCollection.onNameConflictResolved(fileNameOptions)
    onResolved(FileOptionsCollection.getState())
  }

  const onCloseResolveModals = () => {
    // user dismissed a zip or name conflict modal
    FileOptionsCollection.resetState()
    onClose(FileOptionsCollection.getState())
  }

  if (!fileOptions) return null

  const zipOptions = fileOptions.zipOptions
  const nameCollisions = fileOptions.nameCollisions

  if (zipOptions.length)
    return createPortal(
      <ZipFileOptionsForm
        open={!!zipOptions.length}
        onClose={onCloseResolveModals}
        fileOptions={zipOptions[0]}
        onZipOptionsResolved={onZipOptionsResolved}
      />,
      document.body,
    )
  else if (nameCollisions.length)
    return createPortal(
      <FileRenameForm
        open={!!nameCollisions.length}
        onClose={onCloseResolveModals}
        fileOptions={nameCollisions[0]}
        onNameConflictResolved={onNameConflictResolved}
      />,
      document.body,
    )
  else return null
}
