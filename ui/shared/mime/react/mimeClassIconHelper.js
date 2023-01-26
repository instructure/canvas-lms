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
import {useScope as useI18nScope} from '@canvas/i18n'
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
  IconZippedLine,
} from '@instructure/ui-icons'

const I18n = useI18nScope('mime_class_icons')

export const DEFAULT_ICON = <IconPaperclipLine title={I18n.t('File')} />

export const ICON_TYPES = {
  audio: <IconAttachMediaLine title={I18n.t('Audio File')} />,
  code: <IconCodeLine title={I18n.t('Code File')} />,
  doc: <IconDocumentLine title={I18n.t('Doc File')} />,
  file: <IconPaperclipLine title={I18n.t('File')} />,
  flash: <IconPaperclipLine title={I18n.t('Flash File')} />,
  folder: <IconFolderLine title={I18n.t('Folder')} />,
  'folder-locked': <IconFolderLockedLine title={I18n.t('Folder Locked')} />,
  html: <IconCodeLine title={I18n.t('HTML File')} />,
  image: <IconImageLine title={I18n.t('Image File')} />,
  pdf: <IconPdfLine title={I18n.t('PDF File')} />,
  ppt: <IconMsPptLine title={I18n.t('PowerPoint File')} />,
  text: <IconDocumentLine title={I18n.t('Text File')} />,
  video: <IconAttachMediaLine title={I18n.t('Video File')} />,
  xls: <IconMsExcelLine title={I18n.t('Excel File')} />,
  zip: <IconZippedLine title={I18n.t('Zip File')} />,
}

export function getIconByType(attachment_type) {
  return ICON_TYPES[attachment_type] || DEFAULT_ICON
}
