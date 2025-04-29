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

import React, {useState} from 'react'
import {getFilesEnv} from '../../../utils/filesEnvUtils'
import {Table} from '@instructure/ui-table'
import {useScope as createI18nScope} from '@canvas/i18n'
import FilesHeader from '../FilesHeader/FilesHeader'
import AllContextsNameLink from './AllContextsNameLink'
import {Responsive} from '@instructure/ui-responsive'
import canvasTheme from '@instructure/ui-themes'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('files_v2')

interface AllMyFilesTableProps {
  size: 'small' | 'medium' | 'large'
}

const AllMyFilesTable = ({size}: AllMyFilesTableProps) => {
  const [sortDir, setSortDir] = useState<'ascending' | 'descending' | 'none'>('none')
  const contexts = getFilesEnv().contexts

  const handleRequestSort = () => {
    const newSortDir = sortDir === 'ascending' ? 'descending' : 'ascending'
    setSortDir(newSortDir)
  }

  const renderSortedRows = () => {
    const sortedContexts =
      sortDir === 'none'
        ? contexts
        : // doesn't mutate the original array
          [...contexts].sort((a, b) => {
            return sortDir === 'ascending'
              ? a.name.localeCompare(b.name)
              : b.name.localeCompare(a.name)
          })

    return sortedContexts.map(context => (
      <Table.Row key={context.name + context.root_folder_id}>
        <Table.Cell>
          <AllContextsNameLink
            name={context.name}
            contextType={context.contextType}
            contextId={context.contextId}
          />
        </Table.Cell>
      </Table.Row>
    ))
  }

  return (
    <>
      <FilesHeader size={size} isUserContext={true} shouldHideUploadButtons={true} />
      <Flex justifyItems="space-between" margin="medium 0">
        <Flex.Item shouldGrow={true}>
          <Text>
            <b>{I18n.t('All My Files')}</b>
          </Text>
        </Flex.Item>
      </Flex>
      <Table caption={I18n.t('All My Files')} hover={true}>
        <Table.Head renderSortLabel={I18n.t('Sort By')}>
          <Table.Row>
            <Table.ColHeader
              key="name"
              id="name"
              onRequestSort={handleRequestSort}
              sortDirection={sortDir}
            >
              {I18n.t('Name')}
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>{renderSortedRows()}</Table.Body>
      </Table>
      <Alert
        liveRegion={() => document.getElementById('flash_screenreader_holder')!}
        liveRegionPoliteness="polite"
        screenReaderOnly
        data-testid="sort-announcement"
      >
        {sortDir != 'none' &&
          I18n.t('Sorted by name in %{sortDir} order', {
            sortDir,
          })}
      </Alert>
    </>
  )
}

const ResponsiveAllMyFilesTable = () => {
  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: canvasTheme.breakpoints.small},
        medium: {maxWidth: canvasTheme.breakpoints.tablet},
      }}
      render={(_props: any, matches: string[] | undefined) => (
        <AllMyFilesTable size={(matches?.[0] as 'small' | 'medium') || 'large'} />
      )}
    />
  )
}

export default ResponsiveAllMyFilesTable
