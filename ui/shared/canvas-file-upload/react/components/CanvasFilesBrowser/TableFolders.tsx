/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import * as tz from '@instructure/moment-utils'
import {CanvasFolder, ColumnWidths} from '../../types'

import {Flex} from '@instructure/ui-flex'
import {
  IconCheckMarkIndeterminateLine,
  IconFolderLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('canvas_file_upload')

interface FolderButtonProps {
  elementId?: string
  folderID: string
  handleFolderSelect: (id: string) => void
  tip: string
  children: React.ReactNode
}

const FolderButton: React.FC<FolderButtonProps> = props => {
  return (
    <div
      className="file-select-item"
      id={props.elementId || `folder-${props.folderID}`}
      onClick={() => props.handleFolderSelect(props.folderID)}
      onKeyUp={e => {
        // Keycode 13 is the Return or Enter key
        if (e.keyCode === 13) {
          props.handleFolderSelect(props.folderID)
        }
      }}
      tabIndex={0}
      role="button"
    >
      {props.children}
    </div>
  )
}

const renderFolderName = (folderName: string) => (
  <Text size="small">
    <TruncateText>{folderName}</TruncateText>
  </Text>
)

const renderCreatedAt = (createdAt: string) => (
  <Text size="small">
    <FriendlyDatetime dateTime={createdAt} format={I18n.t('#date.formats.medium')} />
  </Text>
)

const renderPublishedIcon = (locked: boolean) => {
  return locked ? <IconUnpublishedLine /> : <IconPublishSolid color="success" />
}

const formattedDateTime = (dateTime: string) => {
  return tz.format(tz.parse(dateTime), I18n.t('#date.formats.medium'))
}

const renderSRContents = (folder: {name: string; created_at?: string; locked?: boolean}) => {
  const description = []
  description.push(I18n.t('type: folder'))
  description.push(I18n.t('name: %{name}', {name: folder.name}))
  if (folder.hasOwnProperty('created_at')) {
    description.push(
      I18n.t('date created: %{createdAt}', {createdAt: formattedDateTime(folder.created_at!)}),
    )
  }
  if (folder.hasOwnProperty('locked')) {
    description.push(folder.locked ? I18n.t('state: unpublished') : I18n.t('state: published'))
  }

  return <ScreenReaderContent>{description.join(', ')}</ScreenReaderContent>
}

const renderParentFolder = (
  folder: CanvasFolder,
  handleFolderSelect: (id: string) => void,
  columnWidths: ColumnWidths,
) => {
  if (folder.parent_folder_id !== null && folder.parent_folder_id !== undefined) {
    return (
      <FolderButton
        elementId="parent-folder"
        folderID={folder.parent_folder_id.toString()}
        handleFolderSelect={handleFolderSelect}
        tip="../"
      >
        {renderSRContents({name: I18n.t('return to parent folder')})}
        <Flex aria-hidden={true}>
          <Flex.Item padding="xx-small" size={columnWidths.thumbnailWidth}>
            <IconFolderLine size="small" />
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.nameWidth} shouldGrow={true}>
            {renderFolderName('../')}
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.dateCreatedWidth}>
            <IconCheckMarkIndeterminateLine />
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.dateModifiedWidth}>
            <IconCheckMarkIndeterminateLine />
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.modifiedByWidth}>
            <IconCheckMarkIndeterminateLine />
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.fileSizeWidth}>
            <IconCheckMarkIndeterminateLine />
          </Flex.Item>
          <Flex.Item padding="xx-small" size={columnWidths.publishedWidth}>
            <IconCheckMarkIndeterminateLine />
          </Flex.Item>
        </Flex>
      </FolderButton>
    )
  }
}

interface TableFoldersProps {
  columnWidths: ColumnWidths
  folders: Record<string, CanvasFolder>
  handleFolderSelect: (id: string) => void
  selectedFolderID: string
}

const TableFolders: React.FC<TableFoldersProps> = ({
  columnWidths,
  folders,
  handleFolderSelect,
  selectedFolderID,
}) => {
  return (
    <>
      {renderParentFolder(folders[selectedFolderID], handleFolderSelect, columnWidths)}
      {folders[selectedFolderID].subFolderIDs.map(id => {
        const folder = folders[id]
        return (
          <FolderButton
            key={folder.id}
            folderID={folder.id}
            handleFolderSelect={handleFolderSelect}
            tip={folder.name}
          >
            {renderSRContents(folder)}
            <Flex aria-hidden={true}>
              <Flex.Item padding="xx-small" size={columnWidths.thumbnailWidth}>
                <IconFolderLine size="small" />
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.nameWidth} shouldGrow={true}>
                {renderFolderName(folder.name)}
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.dateCreatedWidth}>
                {folder.created_at ? (
                  renderCreatedAt(folder.created_at)
                ) : (
                  <IconCheckMarkIndeterminateLine />
                )}
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.dateModifiedWidth}>
                <IconCheckMarkIndeterminateLine />
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.modifiedByWidth}>
                <IconCheckMarkIndeterminateLine />
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.fileSizeWidth}>
                <IconCheckMarkIndeterminateLine />
              </Flex.Item>
              <Flex.Item padding="xx-small" size={columnWidths.publishedWidth}>
                {folder.locked !== undefined ? (
                  renderPublishedIcon(folder.locked)
                ) : (
                  <IconCheckMarkIndeterminateLine />
                )}
              </Flex.Item>
            </Flex>
          </FolderButton>
        )
      })}
    </>
  )
}

export default TableFolders
