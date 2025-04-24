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
import {useScope as createI18nScope} from '@canvas/i18n'
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

const I18n = createI18nScope('mime_class_icons')

export const DEFAULT_ICON_TITLE = I18n.t('File')

export const ICON_TITLES = {
  audio: I18n.t('Audio File'),
  code: I18n.t('Code File'),
  doc: I18n.t('Doc File'),
  file: I18n.t('File'),
  flash: I18n.t('Flash File'),
  folder: I18n.t('Folder'),
  'folder-locked': I18n.t('Folder Locked'),
  html: I18n.t('HTML File'),
  image: I18n.t('Image File'),
  pdf: I18n.t('PDF File'),
  ppt: I18n.t('PowerPoint File'),
  text: I18n.t('Text File'),
  video: I18n.t('Video File'),
  xls: I18n.t('Excel File'),
  zip: I18n.t('Zip File'),
}

export const DEFAULT_ICON = <IconPaperclipLine title={DEFAULT_ICON_TITLE} />

export const ICON_TYPES = {
  audio: <IconAttachMediaLine title={ICON_TITLES.audio} />,
  code: <IconCodeLine title={ICON_TITLES.code} />,
  doc: <IconDocumentLine title={ICON_TITLES.doc} />,
  file: <IconPaperclipLine title={ICON_TITLES.file} />,
  flash: <IconPaperclipLine title={ICON_TITLES.flash} />,
  folder: <IconFolderLine title={ICON_TITLES.folder} />,
  'folder-locked': <IconFolderLockedLine title={ICON_TITLES['folder-locked']} />,
  html: <IconCodeLine title={ICON_TITLES.html} />,
  image: <IconImageLine title={ICON_TITLES.image} />,
  pdf: <IconPdfLine title={ICON_TITLES.pdf} />,
  ppt: <IconMsPptLine title={ICON_TITLES.ppt} />,
  text: <IconDocumentLine title={ICON_TITLES.text} />,
  video: <IconAttachMediaLine title={ICON_TITLES.video} />,
  xls: <IconMsExcelLine title={ICON_TITLES.xls} />,
  zip: <IconZippedLine title={ICON_TITLES.zip} />,
}

export function getIconByType(attachment_type) {
  return ICON_TYPES[attachment_type] || DEFAULT_ICON
}
