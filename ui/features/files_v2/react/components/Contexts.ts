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

import {createContext} from 'react'
import {BBFolderWrapper} from 'features/files_v2/utils/fileFolderWrappers'
import {type Folder} from 'features/files_v2/interfaces/File'

interface FileManagementContextProps {
  folderId: string
  contextType: string
  contextId: string
  showingAllContexts: boolean
  rootFolder?: Folder
  currentFolder?: BBFolderWrapper | null
}

export const FileManagementContext = createContext({} as FileManagementContextProps)
