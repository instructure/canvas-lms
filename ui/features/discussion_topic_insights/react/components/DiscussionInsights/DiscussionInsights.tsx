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

import React, {useState, useMemo} from 'react'
import {Text} from '@instructure/ui-text'
import InsightsTable from '../InsightsTable/InsightsTable'
import {View} from '@instructure/ui-view'
import {Header, Row} from '../InsightsTable/SimpleTable'
import Placeholder from './Placeholder'
import InsightsHeader from '../InsightsHeader/InsightsHeader'
import InsightsActionBar from '../InsightsActionBar/InsightsActionBar'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useInsight} from '../../hooks/useFetchInsights'
import {formatDate, getStatusByRelevance} from '../../utils'
import InsightsReviewRatings from '../InsightsReviewRatings/InsightsReviewRatings'
import useInsightStore from '../../hooks/useInsightStore'
import {Button} from '@instructure/ui-buttons'
import NewActivityInfo from '../NewActivityInfo/NewActivityInfo'

const I18n = createI18nScope('discussion_insights')

const headers: Header[] = [
  {
    id: 'relevance',
    text: I18n.t('Relevance'),
    width: 'fit-content',
    alignment: 'center',
    sortAble: true,
  },
  {
    id: 'name',
    text: I18n.t('Student Name'),
    width: 'fit-content',
    alignment: 'start',
    sortAble: true,
  },
  {
    id: 'notes',
    text: I18n.t('Evaluation Notes'),
    width: '45%',
    alignment: 'start',
    sortAble: false,
  },
  {
    id: 'review',
    text: I18n.t('Review'),
    width: 'fit-content',
    alignment: 'center',
    sortAble: true,
  },
  {
    id: 'date',
    text: I18n.t('Time Posted'),
    width: 'fit-content',
    alignment: 'center',
    sortAble: true,
  },
  {
    id: 'actions',
    text: I18n.t('Actions'),
    width: 'fit-content',
    alignment: 'center',
    sortAble: false,
  },
]

const DiscussionInsights: React.FC = () => {
  const [query, setQuery] = useState('')

  const context = useInsightStore(state => state.context)
  const contextId = useInsightStore(state => state.contextId)
  const discussionId = useInsightStore(state => state.discussionId)

  const setModalOpen = useInsightStore(state => state.setModalOpen)

  const {loading, insight, insightError, entries, entryCount} = useInsight(
    context,
    contextId,
    discussionId,
  )

  let placeholderContent = null

  const handleGenerateInsights = async () => {
    // TODO: VICE-5178
    console.log('Generate insights clicked')
  }

  if (insightError) {
    placeholderContent = (
      <Placeholder
        type="error"
        errorType="loading"
        // TODO: VICE-5178
        onClick={() => console.log('Generate clicked')}
      />
    )
  }

  if (!placeholderContent && insight?.workflow_state === 'failed') {
    placeholderContent = (
      // TODO: VICE-5178
      <Placeholder type="error" errorType="generating" onClick={() => console.log('click')} />
    )
  }

  if (!placeholderContent && loading && !insight) {
    placeholderContent = <Placeholder type="loading" />
  }

  if (!placeholderContent && insight && !insight.workflow_state && !entries) {
    // TODO: VICE-5178
    placeholderContent = <Placeholder type="no-data" onClick={() => console.log('generate')} />
  }

  if (!placeholderContent && !loading && entryCount === 0) {
    placeholderContent = <Placeholder type="no-reply" />
  }

  const handleSearch = (query: string) => {
    setQuery(query)
  }

  const filteredEntries = useMemo(() => {
    if (!entries) {
      return []
    }

    if (!query) {
      return entries
    }

    return entries.filter(row => row.student_name.toLowerCase().includes(query.toLowerCase()))
  }, [entries, query])

  const searchResultsText = I18n.t(
    {
      one: '1 Result',
      other: '%{count} Results',
    },
    {count: filteredEntries.length},
  )

  const tableRows: Row[] = filteredEntries.map(item => ({
    relevance: getStatusByRelevance(
      item.relevance_ai_classification,
    ),
    name: item.student_name,
    notes: item.relevance_ai_evaluation_notes,
    review: <InsightsReviewRatings />,
    date: formatDate(new Date(item.entry_updated_at)),
    actions: (
      <Button size="small" onClick={() => setModalOpen(true)}>
        {I18n.t('See Reply')}
      </Button>
    ),
  }))

  if (!placeholderContent && !loading && filteredEntries.length === 0) {
    placeholderContent = <Placeholder type="no-results" />
  }

  return (
    <>
      <InsightsHeader />
      {insight?.needs_processing && <NewActivityInfo />}
      <InsightsActionBar
        loading={loading}
        entryCount={entryCount}
        onSearch={handleSearch}
        onGenerateInsights={handleGenerateInsights}
      />
      {!loading && !!entryCount && !!filteredEntries.length && (
        <View as="div" margin="0 0 medium 0">
          <Text color="secondary">{searchResultsText}</Text>
        </View>
      )}
      {placeholderContent}
      {!loading && !placeholderContent && !filteredEntries.length && (
        <Placeholder type="no-results" />
      )}
      {/* TODO: check entryCount logic if we have real data */}
      {!loading && !!entryCount && filteredEntries?.length > 0 && (
        <InsightsTable
          caption="Discussion Insights"
          rows={tableRows}
          headers={headers}
          perPage={20}
        />
      )}
    </>
  )
}

export default DiscussionInsights
