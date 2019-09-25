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

import {formatFileSize, getFileThumbnail} from '../../../../../../shared/helpers/fileHelper'
import FriendlyDatetime from '../../../../../../shared/FriendlyDatetime'
import I18n from 'i18n!assignments_2'
import {object, shape, string} from 'prop-types'
import React from 'react'

import {Flex, FlexItem} from '@instructure/ui-layout'
import {
  IconCheckMarkIndeterminateLine,
  IconPublishSolid,
  IconUnpublishedLine
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Text, TruncateText} from '@instructure/ui-elements'
import {Tooltip} from '@instructure/ui-overlays'

const renderFileName = fileName => (
  <Tooltip tip={fileName} as="div" variant="inverse">
    <Text size="small" tabIndex="0">
      <ScreenReaderContent>{I18n.t(', name: ')}</ScreenReaderContent>
      <TruncateText>{fileName}</TruncateText>
    </Text>
  </Tooltip>
)

const renderDateCreated = createdAt => (
  <Text size="small">
    <ScreenReaderContent>{I18n.t(', date created: ')}</ScreenReaderContent>
    <FriendlyDatetime dateTime={createdAt} format={I18n.t('#date.formats.medium')} />
  </Text>
)

const renderDateModified = modifiedAt => (
  <Text size="small">
    <ScreenReaderContent>{I18n.t(', date modified: ')}</ScreenReaderContent>
    {modifiedAt ? (
      <FriendlyDatetime dateTime={modifiedAt} format={I18n.t('#date.formats.medium')} />
    ) : (
      renderNotApplicableCell()
    )}
  </Text>
)

const renderModifiedBy = user => (
  <Text size="small">
    <ScreenReaderContent>{I18n.t(', modified by: ')}</ScreenReaderContent>
    {user ? user.display_name : renderNotApplicableCell()}
  </Text>
)

const renderFileSize = size => (
  <Text size="small">
    <ScreenReaderContent>{I18n.t(', size: ')}</ScreenReaderContent>
    {size ? formatFileSize(size) : renderNotApplicableCell()}
  </Text>
)

const renderPublishedState = locked => {
  return locked ? (
    <>
      <ScreenReaderContent>{I18n.t(', state: unpublished')}</ScreenReaderContent>
      <IconUnpublishedLine />
    </>
  ) : (
    <>
      <ScreenReaderContent>{I18n.t(', state: published')}</ScreenReaderContent>
      <IconPublishSolid color="success" />
    </>
  )
}

const renderNotApplicableCell = () => (
  <>
    <ScreenReaderContent>{I18n.t('not applicable')}</ScreenReaderContent>
    <IconCheckMarkIndeterminateLine />
  </>
)

const TableFiles = props => {
  return (
    <>
      {props.folders[props.selectedFolderID].subFileIDs.map(id => {
        const file = props.files[id]
        return (
          <div key={file.id}>
            <ScreenReaderContent>{I18n.t('type: file')}</ScreenReaderContent>
            <Flex>
              <FlexItem padding="xx-small" size={props.columnWidths.thumbnailWidth}>
                {getFileThumbnail(file, 'small')}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.nameWidth} grow>
                {renderFileName(file.display_name)}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.dateCreatedWidth}>
                {renderDateCreated(file.created_at)}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.dateModifiedWidth}>
                {renderDateModified(file.updated_at)}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.modifiedByWidth}>
                {renderModifiedBy(file.user)}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.fileSizeWidth}>
                {renderFileSize(file.size)}
              </FlexItem>
              <FlexItem padding="xx-small" size={props.columnWidths.publishedWidth}>
                {renderPublishedState(file.locked)}
              </FlexItem>
            </Flex>
          </div>
        )
      })}
    </>
  )
}

TableFiles.propTypes = {
  columnWidths: shape({
    thumbnailWidth: string,
    nameWidth: string,
    nameAndThumbnailWidth: string,
    dateCreatedWidth: string,
    dateModifiedWidth: string,
    modifiedByWidth: string,
    fileSizeWidth: string,
    publishedWidth: string
  }),
  // eslint-disable-next-line react/forbid-prop-types
  files: object,
  // eslint-disable-next-line react/forbid-prop-types
  folders: object,
  selectedFolderID: string
}

export default TableFiles
