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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {type File, type Folder} from '../../../interfaces/File'
import {ModalOrTrayOptions, ColumnHeader} from '../../../interfaces/FileFolderTable'
import ActionMenuButton from './ActionMenuButton'
import NameLink from './NameLink'
import PublishIconButton from './PublishIconButton'
import RightsIconButton from './RightsIconButton'
import BlueprintIconButton from './BlueprintIconButton'
import {UpdatedAtDate} from './UpdatedAtDate'
import {ModifiedByLink} from './ModifiedByLink'

const I18n = createI18nScope('files_v2')

export const setColumnWidths = (headers: ColumnHeader[]) => {
  // Use a temporary div to calculate the width of each column
  const temp = document.createElement('div')
  temp.style.position = 'absolute'
  temp.style.visibility = 'hidden'
  temp.style.whiteSpace = 'nowrap'
  temp.style.left = '-9999px'
  temp.style.fontFamily = getComputedStyle(document.body).fontFamily
  temp.style.fontSize = getComputedStyle(document.body).fontSize
  temp.style.fontWeight = 'bold'
  document.body.appendChild(temp)

  const fontSizeInPx = parseFloat(temp.style.fontSize)

  headers.forEach(header => {
    if (header.width) return // some headers have fixed widths
    temp.textContent = header.title
    const width = temp.getBoundingClientRect().width
    const widthInEms = width / fontSizeInPx
    const padding = 1.5
    header.width = `${Math.round(Math.max(3, widthInEms + padding) * 100) / 100}em`
  })
  document.body.removeChild(temp)
}

export const getColumnHeaders = (actionsTitle: string, currentSortId: string): ColumnHeader[] => [
  {
    id: 'name',
    title: I18n.t('Name'),
    textAlign: 'start',
    width: '12.5em',
    isSortable: true,
    screenReaderLabel: currentSortId === 'name' ? I18n.t('Sorted by name') : I18n.t('Sort by name'),
  },
  {
    id: 'created_at',
    title: I18n.t('Created'),
    textAlign: 'start',
    width: undefined,
    isSortable: true,
    screenReaderLabel:
      currentSortId === 'created_at' ? I18n.t('Sorted by created') : I18n.t('Sort by created'),
  },
  {
    id: 'updated_at',
    title: I18n.t('Last Modified'),
    textAlign: 'start',
    width: undefined,
    isSortable: true,
    screenReaderLabel:
      currentSortId === 'updated_at'
        ? I18n.t('Sorted by last modified')
        : I18n.t('Sort by last modified'),
  },
  {
    id: 'modified_by',
    title: I18n.t('Modified By'),
    textAlign: 'start',
    width: undefined,
    isSortable: true,
    screenReaderLabel:
      currentSortId === 'modified_by'
        ? I18n.t('Sorted by modified by')
        : I18n.t('Sort by modified by'),
  },
  {
    id: 'size',
    title: I18n.t('Size'),
    textAlign: 'start',
    width: '',
    isSortable: true,
    screenReaderLabel: currentSortId === 'size' ? I18n.t('Sorted by size') : I18n.t('Sort by size'),
  },
  {
    id: 'rights',
    title: I18n.t('Rights'),
    textAlign: 'center',
    width: undefined,
    isSortable: true,
    screenReaderLabel:
      currentSortId === 'rights' ? I18n.t('Sorted by rights') : I18n.t('Sort by rights'),
  },
  {
    id: 'blueprint',
    title: I18n.t('Blueprint'),
    textAlign: 'center',
    width: undefined,
    isSortable: false,
  },
  {
    id: 'permissions',
    title: I18n.t('Status'),
    textAlign: 'center',
    width: undefined,
    isSortable: false,
  },
  {id: 'actions', title: actionsTitle, textAlign: 'center', width: '', isSortable: false},
]

export const columnRenderers: {
  [key: string]: ({
    row,
    rows,
    isStacked,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    userCanRestrictFilesForContext,
    usageRightsRequiredForContext,
    size,
    isSelected,
    toggleSelect,
    setModalOrTrayOptions,
    rowIndex,
  }: {
    row: File | Folder
    rows: (File | Folder)[]
    isStacked: boolean
    userCanEditFilesForContext: boolean
    userCanDeleteFilesForContext: boolean
    userCanRestrictFilesForContext: boolean
    usageRightsRequiredForContext: boolean
    size: 'small' | 'medium' | 'large'
    isSelected: boolean
    toggleSelect: () => void
    setModalOrTrayOptions: (modalOrTray: ModalOrTrayOptions | null) => () => void
    rowIndex: number
  }) => React.ReactNode
} = {
  name: ({row, rows, isStacked}) => <NameLink isStacked={isStacked} item={row} collection={rows} />,
  created_at: ({row}) => (
    <FriendlyDatetime dateTime={row.created_at} includeScreenReaderContent={false} />
  ),
  updated_at: ({row, isStacked}) => (
    <UpdatedAtDate updatedAt={row.updated_at} isStacked={isStacked} />
  ),
  modified_by: ({row, isStacked}) =>
    'user' in row && row.user?.display_name ? (
      <ModifiedByLink
        htmlUrl={row.user.html_url}
        displayName={row.user.display_name}
        isStacked={isStacked}
      />
    ) : null,
  size: ({row}) =>
    'size' in row ? <Text>{friendlyBytes(row.size)}</Text> : <Text>{I18n.t('--')}</Text>,
  rights: ({
    row,
    userCanEditFilesForContext,
    usageRightsRequiredForContext,
    setModalOrTrayOptions,
  }) =>
    row.folder_id && usageRightsRequiredForContext ? (
      <RightsIconButton
        usageRights={row.usage_rights}
        userCanEditFilesForContext={userCanEditFilesForContext}
        onClick={setModalOrTrayOptions({id: 'manage-usage-rights', items: [row]})}
      />
    ) : null,
  blueprint: ({row}) => <BlueprintIconButton item={row} />,
  permissions: ({row, userCanRestrictFilesForContext, setModalOrTrayOptions}) => (
    <PublishIconButton
      item={row}
      userCanRestrictFilesForContext={userCanRestrictFilesForContext}
      onClick={setModalOrTrayOptions({id: 'permissions', items: [row]})}
    />
  ),
  actions: ({
    row,
    size,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    userCanRestrictFilesForContext,
    usageRightsRequiredForContext,
    rowIndex,
  }) => (
    <ActionMenuButton
      size={size}
      userCanEditFilesForContext={userCanEditFilesForContext}
      userCanDeleteFilesForContext={userCanDeleteFilesForContext}
      userCanRestrictFilesForContext={userCanRestrictFilesForContext}
      usageRightsRequiredForContext={usageRightsRequiredForContext}
      row={row}
      rowIndex={rowIndex}
    />
  ),
}

export const getSelectionScreenReaderText = (selected: number, total: number) => {
  return I18n.t('%{selected} of %{total} selected', {
    selected,
    total,
  })
}
