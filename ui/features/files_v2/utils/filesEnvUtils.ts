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

import {createFilesEnv} from '@canvas/files_v2/react/modules/filesEnvFactory'
import {FileContext, FilesEnv} from '@canvas/files_v2/react/modules/filesEnvFactory.types'

let _filesEnv: FilesEnv | null = null

export const getFilesEnv = (customFilesContexts?: FileContext[]) => {
  if (!_filesEnv) {
    _filesEnv = createFilesEnv(customFilesContexts)
  }
  return _filesEnv
}

export const resetFilesEnv = () => {
  _filesEnv = null
}

export const resetAndGetFilesEnv = (customFilesContexts?: FileContext[]) => {
  resetFilesEnv()
  return getFilesEnv(customFilesContexts)
}
