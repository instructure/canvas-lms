/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Table} from '@instructure/ui-table'
import {FileDrop} from '@instructure/ui-file-drop'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {IconUploadLine} from '@instructure/ui-icons'

const I18n = useI18nScope('files_v2')
interface Column {
  id: string
  title: string
  textAlign?: 'start' | 'center' | 'end'
  width?: string
}
interface FileFolderTableProps {
  size: 'small' | 'medium' | 'large'
}

const FileFolderTable = ({size}: FileFolderTableProps) => {
  const allColumns: Column[] = [
    {id: 'name', title: I18n.t('Name'), textAlign: 'start', width: '19em'},
    {id: 'created', title: I18n.t('Created'), width: '6.875em'},
    {id: 'lastModified', title: I18n.t('Last Modified'), width: '8.75em'},
    {id: 'modifiedBy', title: I18n.t('Modified By'), width: '9.735em'},
    {id: 'size', title: I18n.t('Size'), width: '6em'},
    {id: 'rights', title: I18n.t('Rights'), width: '5.125em'},
    {id: 'published', title: I18n.t('Published'), width: '6.625em'},
    {id: 'actions', title: '', width: '3em'},
  ]

  const columnVisibility = {
    small: ['name', 'actions'],
    medium: ['name', 'created', 'lastModified', 'rights', 'published', 'actions'],
    large: [
      'name',
      'created',
      'lastModified',
      'modifiedBy',
      'size',
      'rights',
      'published',
      'actions',
    ],
  }

  const renderColumns = () => {
    const visibleColumns = columnVisibility[size]
    const columns = allColumns.filter(column => visibleColumns.includes(column.id))
    return columns.map(column => (
      <Table.ColHeader
        key={column.id}
        id={column.id}
        textAlign={column.textAlign}
        width={column.width}
        data-testid={column.id}
      >
        {column.title}
      </Table.ColHeader>
    ))
  }

  return (
    <>
      <Table caption={I18n.t('Files and Folders')} hover={true} layout="auto">
        <Table.Head>
          <Table.Row>{renderColumns()}</Table.Row>
        </Table.Head>
        <Table.Body />
      </Table>
      <View as="div" padding="large none none none">
        <FileDrop
          renderLabel={
            <View as="div" padding="xx-large large" background="primary">
              <IconUploadLine size="large" />
              <Heading margin="medium 0 small 0">{I18n.t('Drag a file here, or')}</Heading>
              <Text color="brand">{I18n.t('Choose a file to upload')}</Text>
            </View>
          }
        />
      </View>
    </>
  )
}

export default FileFolderTable
