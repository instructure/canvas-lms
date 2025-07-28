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

import {ColumnID} from '../react/components/FileFolderTable/FileFolderTableUtils'
import {type File, type Folder} from './File'

export interface ColumnHeader {
  id: ColumnID
  title: string
  textAlign: 'start' | 'center' | 'end'
  width?: string
  isSortable: boolean
  screenReaderLabel?: string
}

export type ModalOrTrayOptions = {
  id: 'manage-usage-rights' | 'permissions'
  items: (File | Folder)[]
}
