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

import {formatFileSize, getFileThumbnail} from '@canvas/util/fileHelper'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import * as tz from '@instructure/moment-utils'

import {Flex} from '@instructure/ui-flex'
import {
  IconCheckMarkIndeterminateLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('assignments_2')

interface FileButtonProps {
  tip: string
  selected: boolean
  onClick: () => void
  children: React.ReactNode
}

const FileButton: React.FC<FileButtonProps> = props => {
  return (
    <Tooltip renderTip={props.tip} as="div" color="primary">
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
    </Tooltip>
  )
}

interface File {
  id: string
  display_name: string
  filename: string
  created_at: string
  updated_at?: string
  user?: {
    display_name: string
  }
  size?: number
  locked: boolean
}

interface Folder {
  subFileIDs: string[]
}

interface TableFilesProps {
  allowedExtensions?: string[]
  columnWidths: {
    thumbnailWidth: string
    nameWidth: string
    nameAndThumbnailWidth: string
    dateCreatedWidth: string
    dateModifiedWidth: string
    modifiedByWidth: string
    fileSizeWidth: string
    publishedWidth: string
  }
  files: Record<string, File>
  folders: Record<string, Folder>
  handleCanvasFileSelect: (id: string) => void
  selectedFolderID: string
}

interface TableFilesState {
  selectedFileID: string | null
}

class TableFiles extends React.Component<TableFilesProps, TableFilesState> {
  static defaultProps = {
    allowedExtensions: [],
  }

  state = {
    selectedFileID: null,
  }

  formattedDateTime = (dateTime: string) => {
    return tz.format(tz.parse(dateTime), I18n.t('#date.formats.medium'))
  }

  allowedExtension = (filename: string) => {
    if (!this.props.allowedExtensions!.length) return true

    const delimiterPosition = (filename || '').lastIndexOf('.')
    // Position will be < 1 if there's no delimiter (-1) or no filename before
    // the delimiter (0)
    if (delimiterPosition < 1) {
      return false
    }

    const extension = filename.slice(delimiterPosition + 1).toLowerCase()
    if (!extension) return false

    return this.props.allowedExtensions!.some(ext => ext.toLowerCase() === extension)
  }

  renderSRContents = (file: File) => {
    const description = []
    description.push(I18n.t('type: file'))
    description.push(I18n.t('name: %{name}', {name: file.display_name}))
    description.push(
      I18n.t('date created: %{createdAt}', {createdAt: this.formattedDateTime(file.created_at)}),
    )
    if (file.hasOwnProperty('updated_at')) {
      description.push(
        I18n.t('date modified: %{modifiedAt}', {
          modifiedAt: this.formattedDateTime(file.updated_at!),
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

  renderFileName = (fileName: string) => (
    <Text size="small">
      <TruncateText>{fileName}</TruncateText>
    </Text>
  )

  renderDateCreated = (createdAt: string) => (
    <Text size="small">
      <FriendlyDatetime dateTime={createdAt} format={I18n.t('#date.formats.medium')} />
    </Text>
  )

  renderDateModified = (modifiedAt?: string) => (
    <Text size="small">
      {modifiedAt ? (
        <FriendlyDatetime dateTime={modifiedAt} format={I18n.t('#date.formats.medium')} />
      ) : (
        <IconCheckMarkIndeterminateLine />
      )}
    </Text>
  )

  renderModifiedBy = (user?: {display_name: string}) => (
    <Text size="small">
      {user ? <TruncateText>{user.display_name}</TruncateText> : <IconCheckMarkIndeterminateLine />}
    </Text>
  )

  renderFileSize = (size?: number) => (
    <Text size="small">{size ? formatFileSize(size) : <IconCheckMarkIndeterminateLine />}</Text>
  )

  renderPublishedState = (locked: boolean) => {
    return locked ? <IconUnpublishedLine /> : <IconPublishSolid color="success" />
  }

  render() {
    return (
      <>
        {this.props.folders[this.props.selectedFolderID].subFileIDs.reduce<React.ReactElement[]>(
          (buttons, id) => {
            const file = this.props.files[id]
            if (this.allowedExtension(file.filename)) {
              const button = (
                <FileButton
                  key={id}
                  selected={this.state.selectedFileID === id}
                  onClick={() => {
                    this.setState({selectedFileID: id})
                    this.props.handleCanvasFileSelect(id)
                  }}
                  tip={file.display_name}
                >
                  {this.renderSRContents(file)}
                  <Flex aria-hidden={true}>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.thumbnailWidth}>
                      {getFileThumbnail(file, 'small')}
                    </Flex.Item>
                    <Flex.Item
                      padding="xx-small"
                      size={this.props.columnWidths.nameWidth}
                      shouldGrow={true}
                    >
                      {this.renderFileName(file.display_name)}
                    </Flex.Item>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.dateCreatedWidth}>
                      {this.renderDateCreated(file.created_at)}
                    </Flex.Item>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.dateModifiedWidth}>
                      {this.renderDateModified(file.updated_at)}
                    </Flex.Item>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.modifiedByWidth}>
                      {this.renderModifiedBy(file.user)}
                    </Flex.Item>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.fileSizeWidth}>
                      {this.renderFileSize(file.size)}
                    </Flex.Item>
                    <Flex.Item padding="xx-small" size={this.props.columnWidths.publishedWidth}>
                      {this.renderPublishedState(file.locked)}
                    </Flex.Item>
                  </Flex>
                </FileButton>
              )

              buttons.push(button)
            }

            return buttons
          },
          [],
        )}
      </>
    )
  }
}

export default TableFiles
