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
import React, {useState} from 'react'
import InsightsTable from '../InsightsTable/InsightsTable'
import {Header, Row} from '../InsightsTable/SimpleTable'
import InsightsHeader from '../InsightsHeader/InsightsHeader'
import InsightsActionBar from '../InsightsActionBar/InsightsActionBar'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

type DiscussionInsightsProps = {
  headers: Header[]
  rows: Row[]
}

const DiscussionInsights: React.FC<DiscussionInsightsProps> = ({headers, rows}) => {
  const [filteredRows, setFilteredRows] = useState(rows)

  const handleSearch = (query: string) => {
    if (!query) {
      setFilteredRows(rows)
    } else {
      const results = rows.filter((row: Row) =>
        row.name.toLowerCase().includes(query.toLowerCase()),
      )
      setFilteredRows(results)
    }
  }

  const searchResultsText = I18n.t(
    {
      one: '1 Result',
      other: '%{count} Results',
    },
    {count: filteredRows.length},
  )

  return (
    <>
      <InsightsHeader />
      <InsightsActionBar handleSearch={handleSearch} />
      <View as="div" padding="medium 0">
        <Text color="secondary">{searchResultsText}</Text>
      </View>
      <InsightsTable
        caption="Discussion Insights"
        headers={headers}
        rows={filteredRows}
        perPage={20}
      />
    </>
  )
}

export default DiscussionInsights
