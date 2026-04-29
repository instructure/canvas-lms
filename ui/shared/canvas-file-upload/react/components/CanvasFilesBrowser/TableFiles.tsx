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

import {formatFileSize, getFileThumbnail} from '@canvas/util/fileHelper'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import * as tz from '@instructure/moment-utils'
import {CanvasFile, CanvasFolder, ColumnWidths} from '../../types'

import {Flex} from '@instructure/ui-flex'
import {
  IconCheckMarkIndeterminateLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('canvas_file_upload')

interface FileButtonProps {
  tip: string
  selected: boolean
  onClick: () => void
  children: React.ReactNode
}

const FileButton: React.FC<FileButtonProps> = props => {
  return (
    <div
      className={`file-select-item ${props.selected ? 'file-select-item-selected' : ''}`}
      onClick={props.onClick}
      onKeyUp={(e: React.KeyboardEvent) => {
        // Keycode 13 is the Return or Enter key
        if (e.keyCode === 13) {
          props.onClick()
        }
      }}
      tabIndex={0}
      role="button"
    >
      {props.children}
    </div>
  )
}

interface TableFilesProps {
  allowedExtensions?: string[]
  columnWidths: ColumnWidths
  files: Record<string, CanvasFile>
  folders: Record<string, CanvasFolder>
  handleCanvasFileSelect: (id: string) => void
  selectedFolderID: string
}

const TableFiles: React.FC<TableFilesProps> = ({
  allowedExtensions = [],
  columnWidths,
  files,
  folders,
  handleCanvasFileSelect,
  selectedFolderID,
}) => {
  const [selectedFileID, setSelectedFileID] = useState<string | null>(null)

  const formattedDateTime = (dateTime: string) => {
    return tz.format(tz.parse(dateTime), I18n.t('#date.formats.medium'))
  }

  const allowedExtension = (filename: string) => {
    if (!allowedExtensions.length) return true

    const delimiterPosition = (filename || '').lastIndexOf('.')
    // Position will be < 1 if there's no delimiter (-1) or no filename before
    // the delimiter (0)
    if (delimiterPosition < 1) {
      return false
    }

    const extension = filename.slice(delimiterPosition + 1).toLowerCase()
    if (!extension) return false

    // allowedExtensions may include the dot (e.g., '.pdf') or not (e.g., 'pdf')
    // Normalize by removing leading dot from allowed extensions before comparing
    return allowedExtensions.some(ext => {
      const normalizedExt = ext.toLowerCase().replace(/^\./, '')
      return normalizedExt === extension
    })
  }

  const renderSRContents = (file: CanvasFile) => {
    const description = []
    description.push(I18n.t('type: file'))
    description.push(I18n.t('name: %{name}', {name: file.display_name}))
    description.push(
      I18n.t('date created: %{createdAt}', {createdAt: formattedDateTime(file.created_at)}),
    )
    if (file.hasOwnProperty('updated_at')) {
      description.push(
        I18n.t('date modified: %{modifiedAt}', {
          modifiedAt: formattedDateTime(file.updated_at!),
        }),
      )
    }
    if (file.hasOwnProperty('user')) {
      description.push(I18n.t('modified by: %{user}', {user: file.user!.display_name}))
    }
    if (file.hasOwnProperty('size')) {
      description.push(I18n.t('size: %{size}', {size: formatFileSize(file.size!)}))
    }
    description.push(file.locked ? I18n.t('state: unpublished') : I18n.t('state: published'))

    return <ScreenReaderContent>{description.join(', ')}</ScreenReaderContent>
  }

  const renderFileName = (fileName: string) => (
    <Text size="small">
      <TruncateText>{fileName}</TruncateText>
    </Text>
  )

  const renderDateCreated = (createdAt: string) => (
    <Text size="small">
      <FriendlyDatetime dateTime={createdAt} format={I18n.t('#date.formats.medium')} />
    </Text>
  )

  const renderDateModified = (modifiedAt?: string) => (
    <Text size="small">
      {modifiedAt ? (
        <FriendlyDatetime dateTime={modifiedAt} format={I18n.t('#date.formats.medium')} />
      ) : (
        <IconCheckMarkIndeterminateLine />
      )}
    </Text>
  )

  const renderModifiedBy = (user?: {display_name: string}) => (
    <Text size="small">
      {user ? <TruncateText>{user.display_name}</TruncateText> : <IconCheckMarkIndeterminateLine />}
    </Text>
  )

  const renderFileSize = (size?: number) => (
    <Text size="small">{size ? formatFileSize(size) : <IconCheckMarkIndeterminateLine />}</Text>
  )

  const renderPublishedState = (locked: boolean) => {
    return locked ? <IconUnpublishedLine /> : <IconPublishSolid color="success" />
  }

  return (
    <>
      {folders[selectedFolderID].subFileIDs.reduce<React.ReactElement[]>((buttons, id) => {
        const file = files[id]
        if (allowedExtension(file.filename)) {
          const button = (
            <FileButton
              key={id}
              selected={selectedFileID === id}
              onClick={() => {
                setSelectedFileID(id)
                handleCanvasFileSelect(id)
              }}
              tip={file.display_name}
            >
              {renderSRContents(file)}
              <Flex aria-hidden={true}>
                <Flex.Item padding="xx-small" size={columnWidths.thumbnailWidth}>
                  {getFileThumbnail(file, 'small')}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.nameWidth} shouldGrow={true}>
                  {renderFileName(file.display_name)}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.dateCreatedWidth}>
                  {renderDateCreated(file.created_at)}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.dateModifiedWidth}>
                  {renderDateModified(file.updated_at)}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.modifiedByWidth}>
                  {renderModifiedBy(file.user)}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.fileSizeWidth}>
                  {renderFileSize(file.size)}
                </Flex.Item>
                <Flex.Item padding="xx-small" size={columnWidths.publishedWidth}>
                  {renderPublishedState(file.locked)}
                </Flex.Item>
              </Flex>
            </FileButton>
          )

          buttons.push(button)
        }

        return buttons
      }, [])}
    </>
  )
}

export default TableFiles
