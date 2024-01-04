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
import {arrayOf, func, object, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import * as tz from '@canvas/datetime'

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

const I18n = useI18nScope('assignments_2')

const FileButton = props => {
  return (
    <Tooltip renderTip={props.tip} as="div" color="primary">
      <div
        className={`file-select-item ${props.selected ? 'file-select-item-selected' : ''}`}
        onClick={props.onClick}
        onKeyUp={e => {
          // Keycode 13 is the Return or Enter key
          if (e.keyCode === 13) {
            props.onClick()
          }
        }}
        tabIndex="0"
        role="button"
      >
        {props.children}
      </div>
    </Tooltip>
  )
}

class TableFiles extends React.Component {
  state = {
    selectedFileID: null,
  }

  formattedDateTime = dateTime => {
    return tz.format(tz.parse(dateTime), I18n.t('#date.formats.medium'))
  }

  allowedExtension = filename => {
    if (!this.props.allowedExtensions.length) return true

    const delimiterPosition = (filename || '').lastIndexOf('.')
    // Position will be < 1 if there's no delimiter (-1) or no filename before
    // the delimiter (0)
    if (delimiterPosition < 1) {
      return false
    }

    const extension = filename.slice(delimiterPosition + 1).toLowerCase()
    if (!extension) return false

    return this.props.allowedExtensions.some(ext => ext.toLowerCase() === extension)
  }

  renderSRContents = file => {
    const description = []
    description.push(I18n.t('type: file'))
    description.push(I18n.t('name: %{name}', {name: file.display_name}))
    description.push(
      I18n.t('date created: %{createdAt}', {createdAt: this.formattedDateTime(file.created_at)})
    )
    if (file.hasOwnProperty('updated_at')) {
      description.push(
        I18n.t('date modified: %{modifiedAt}', {
          modifiedAt: this.formattedDateTime(file.updated_at),
        })
      )
    }
    if (file.hasOwnProperty('user')) {
      description.push(I18n.t('modified by: %{user}', {user: file.user.display_name}))
    }
    if (file.hasOwnProperty('size')) {
      description.push(I18n.t('size: %{size}', {size: formatFileSize(file.size)}))
    }
    description.push(file.locked ? I18n.t('state: unpublished') : I18n.t('state: published'))

    return <ScreenReaderContent>{description.join(', ')}</ScreenReaderContent>
  }

  renderFileName = fileName => (
    <Text size="small">
      <TruncateText>{fileName}</TruncateText>
    </Text>
  )

  renderDateCreated = createdAt => (
    <Text size="small">
      <FriendlyDatetime dateTime={createdAt} format={I18n.t('#date.formats.medium')} />
    </Text>
  )

  renderDateModified = modifiedAt => (
    <Text size="small">
      {modifiedAt ? (
        <FriendlyDatetime dateTime={modifiedAt} format={I18n.t('#date.formats.medium')} />
      ) : (
        <IconCheckMarkIndeterminateLine />
      )}
    </Text>
  )

  renderModifiedBy = user => (
    <Text size="small">
      {user ? <TruncateText>{user.display_name}</TruncateText> : <IconCheckMarkIndeterminateLine />}
    </Text>
  )

  renderFileSize = size => (
    <Text size="small">{size ? formatFileSize(size) : <IconCheckMarkIndeterminateLine />}</Text>
  )

  renderPublishedState = locked => {
    return locked ? <IconUnpublishedLine /> : <IconPublishSolid color="success" />
  }

  render() {
    return (
      <>
        {this.props.folders[this.props.selectedFolderID].subFileIDs.reduce((buttons, id) => {
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
        }, [])}
      </>
    )
  }
}

TableFiles.propTypes = {
  allowedExtensions: arrayOf(string),
  columnWidths: shape({
    thumbnailWidth: string,
    nameWidth: string,
    nameAndThumbnailWidth: string,
    dateCreatedWidth: string,
    dateModifiedWidth: string,
    modifiedByWidth: string,
    fileSizeWidth: string,
    publishedWidth: string,
  }),
  files: object,
  folders: object,
  handleCanvasFileSelect: func,
  selectedFolderID: string,
}

TableFiles.defaultProps = {
  allowedExtensions: [],
}

export default TableFiles
