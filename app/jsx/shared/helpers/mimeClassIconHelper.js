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

import IconAttachMedia from '@instructure/ui-icons/lib/Line/IconAttachMedia'
import IconDocument from '@instructure/ui-icons/lib/Line/IconDocument'
import IconFolder from '@instructure/ui-icons/lib/Line/IconFolder'
import IconFolderLocked from '@instructure/ui-icons/lib/Line/IconFolderLocked'
import IconImage from '@instructure/ui-icons/lib/Line/IconImage'
import IconMsExcel from '@instructure/ui-icons/lib/Line/IconMsExcel'
import IconMsPpt from '@instructure/ui-icons/lib/Line/IconMsPpt'
import IconPdf from '@instructure/ui-icons/lib/Line/IconPdf'
import IconPaperclip from '@instructure/ui-icons/lib/Line/IconPaperclip'
import IconZipped from '@instructure/ui-icons/lib/Line/IconZipped'

export const DEFAULT_ICON = <IconPaperclip />

export const ICON_TYPES = {
  'audio': <IconAttachMedia />,
  'doc': <IconDocument />,
  'file': <IconPaperclip />,
  'folder': <IconFolder />,
  'folder-locked': <IconFolderLocked />,
  'image': <IconImage />,
  'pdf': <IconPdf />,
  'ppt': <IconMsPpt />,
  'text': <IconDocument />,
  'video': <IconAttachMedia />,
  'xls': <IconMsExcel />,
  'zip': <IconZipped />
}

export function getIconByType(attachment_type) {
  return ICON_TYPES[attachment_type] || DEFAULT_ICON
}
