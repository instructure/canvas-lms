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

import {arrayOf, func, object, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import TableFiles from './TableFiles'
import TableFolders from './TableFolders'
import TableHeader from './TableHeader'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('assignments_2')

const foldersPresent = folder => {
  return folder && folder.subFolderIDs
}

const filesPresent = folder => {
  return folder && folder.subFileIDs && folder.subFileIDs.length > 0
}

const tableColumnWidths = {
  thumbnailWidth: '45px',
  nameWidth: '175px',
  nameAndThumbnailWidth: '220px', // combined for the table heading due to no thumbnail
  dateCreatedWidth: '110px',
  dateModifiedWidth: '110px',
  modifiedByWidth: '110px',
  fileSizeWidth: '80px',
  publishedWidth: '80px',
}

const FileSelectTable = props => {
  return (
    <>
      <ScreenReaderContent>
        {I18n.t('File select, %{filename} folder contents', {
          filename: props.folders[props.selectedFolderID].name,
        })}
      </ScreenReaderContent>
      <TableHeader columnWidths={tableColumnWidths} />
      {foldersPresent(props.folders[props.selectedFolderID]) && (
        <TableFolders
          columnWidths={tableColumnWidths}
          folders={props.folders}
          handleFolderSelect={props.handleFolderSelect}
          selectedFolderID={props.selectedFolderID}
        />
      )}
      {filesPresent(props.folders[props.selectedFolderID]) && (
        <TableFiles
          allowedExtensions={props.allowedExtensions}
          columnWidths={tableColumnWidths}
          files={props.files}
          folders={props.folders}
          handleCanvasFileSelect={props.handleCanvasFileSelect}
          selectedFolderID={props.selectedFolderID}
        />
      )}
    </>
  )
}

FileSelectTable.propTypes = {
  allowedExtensions: arrayOf(string),
  folders: object,
  files: object,
  handleCanvasFileSelect: func,
  handleFolderSelect: func,
  selectedFolderID: string,
}

export default FileSelectTable
