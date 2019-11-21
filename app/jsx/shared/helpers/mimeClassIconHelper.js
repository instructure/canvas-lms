/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React from 'react'
import {
  IconAttachMediaLine,
  IconCodeLine,
  IconDocumentLine,
  IconFolderLine,
  IconFolderLockedLine,
  IconImageLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconPdfLine,
  IconPaperclipLine,
  IconZippedLine
} from '@instructure/ui-icons'

export const DEFAULT_ICON = <IconPaperclipLine />

export const ICON_TYPES = {
  audio: <IconAttachMediaLine />,
  code: <IconCodeLine />,
  doc: <IconDocumentLine />,
  file: <IconPaperclipLine />,
  flash: <IconPaperclipLine />,
  folder: <IconFolderLine />,
  'folder-locked': <IconFolderLockedLine />,
  html: <IconCodeLine />,
  image: <IconImageLine />,
  pdf: <IconPdfLine />,
  ppt: <IconMsPptLine />,
  text: <IconDocumentLine />,
  video: <IconAttachMediaLine />,
  xls: <IconMsExcelLine />,
  zip: <IconZippedLine />
}

export function getIconByType(attachment_type) {
  return ICON_TYPES[attachment_type] || DEFAULT_ICON
}
