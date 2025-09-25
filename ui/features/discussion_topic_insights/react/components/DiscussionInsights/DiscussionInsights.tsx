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

import React, {useState, useMemo, useEffect} from 'react'
import {Text} from '@instructure/ui-text'
import InsightsTable from '../InsightsTable/InsightsTable'
import {View} from '@instructure/ui-view'
import {Header, Row} from '../InsightsTable/SimpleTable'
import Placeholder from './Placeholder'
import InsightsHeader from '../InsightsHeader/InsightsHeader'
import InsightsActionBar from '../InsightsActionBar/InsightsActionBar'
import {useScope as createI18nScope} from '@canvas/i18n'
import {InsightEntry, useInsight} from '../../hooks/useFetchInsights'
import {formatDate} from '../../utils'
import useInsightStore from '../../hooks/useInsightStore'
import {IconButton} from '@instructure/ui-buttons'
import NewActivityInfo from '../NewActivityInfo/NewActivityInfo'
import {IconEyeLine, IconMoveDownBottomLine, IconSpeedGraderLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

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

const filterEntriesbyRelevance = (relevanceFilterType: string, entries: InsightEntry[]) => {
  if (relevanceFilterType === 'all') {
    return entries
  }
  return entries.filter(entry => entry.relevance_ai_classification === relevanceFilterType)
}

const DiscussionInsights: React.FC = () => {
  const [query, setQuery] = useState('')
  const [screenReader, setScreenReader] = useState('')
  const [previousInsightState, setPreviousInsightState] = useState<string | undefined>()
  const [previousLoadingState, setPreviousLoadingState] = useState(false)

  const context = useInsightStore(state => state.context)
  const contextId = useInsightStore(state => state.contextId)
  const discussionId = useInsightStore(state => state.discussionId)
  const SPEEDGRADER_URL_TEMPLATE = useInsightStore(state => state.SPEEDGRADER_URL_TEMPLATE)

  const setEntries = useInsightStore(state => state.setEntries)
  const openEvaluationModal = useInsightStore(state => state.openEvaluationModal)
  const relevanceFilterType = useInsightStore(state => state.filterType)

  const setIsFilteredTable = useInsightStore(state => state.setIsFilteredTable)

  const {
    loading,
    insight,
    insightError,
    generateError,
    generateInsight,
    entries,
    entryCount,
    refetchInsight,
  } = useInsight(context, contextId, discussionId)

  let placeholderContent = null

  const handleGenerateInsights = async () => {
    generateInsight()
  }

  if (insightError) {
    placeholderContent = <Placeholder type="error" errorType="loading" onClick={refetchInsight} />
  }

  if (!placeholderContent && !loading && entryCount === 0) {
    placeholderContent = <Placeholder type="no-reply" />
  }

  if (!placeholderContent && (insight?.workflow_state === 'failed' || generateError)) {
    placeholderContent = (
      <Placeholder type="error" errorType="generating" onClick={handleGenerateInsights} />
    )
  }

  if (!placeholderContent && loading && !insight) {
    placeholderContent = <Placeholder type="loading" />
  }

  if (!loading && ['in_progress', 'created'].includes(insight?.workflow_state || '')) {
    placeholderContent = <Placeholder type="loading" />
  }

  if (!placeholderContent && !loading && insight && !insight.workflow_state && !entries) {
    placeholderContent = <Placeholder type="no-data" onClick={handleGenerateInsights} />
  }

  const handleSearch = (query: string) => {
    setQuery(query)
  }

  const handleSeeReply = (entry: InsightEntry) => {
    openEvaluationModal(entry.id, entry.relevance_human_feedback_notes)
  }

  const filteredEntries = useMemo(() => {
    if (!entries) return []

    const relevanceFilteredValues = filterEntriesbyRelevance(relevanceFilterType, entries)

    if (!query) {
      return relevanceFilteredValues
    }
    return relevanceFilteredValues.filter(row =>
      row.student_name.toLowerCase().includes(query.toLowerCase()),
    )
  }, [entries, query, relevanceFilterType])

  useEffect(() => {
    if (!entries) return

    const relevanceFilteredValues = filterEntriesbyRelevance(relevanceFilterType, entries)
    const hasRelevanceFilter = relevanceFilteredValues !== entries
    const hasSearchFilter = !!query

    setIsFilteredTable(hasRelevanceFilter || hasSearchFilter)
    setEntries(filteredEntries)
  }, [filteredEntries, entries, query, relevanceFilterType, setEntries, setIsFilteredTable])

  const searchResultsText = I18n.t(
    {
      one: '1 Result',
      other: '%{count} Results',
    },
    {count: filteredEntries.length},
  )

  useEffect(() => {
    const isCurrentlyLoading =
      loading || ['created', 'in_progress'].includes(insight?.workflow_state as string)

    if (isCurrentlyLoading && !previousLoadingState) {
      setScreenReader(I18n.t('Insights loading'))
    }

    setPreviousLoadingState(isCurrentlyLoading)
  }, [loading, insight?.workflow_state])

  useEffect(() => {
    if (
      loading ||
      insight?.workflow_state !== 'completed' ||
      previousInsightState === 'completed' ||
      entries?.length === 0
    ) {
      setPreviousInsightState(insight?.workflow_state ?? undefined)
      return
    }

    setScreenReader(I18n.t('Insights generated'))
    setPreviousInsightState(insight?.workflow_state ?? undefined)
  }, [loading, insight?.workflow_state, entries, previousInsightState])

  useEffect(() => {
    if (!query || loading || !entries) {
      return
    }

    const resultCount = filteredEntries.length
    const message =
      resultCount === 0
        ? I18n.t('No results found for "%{searchTerm}"', {searchTerm: query})
        : I18n.t(
            {
              one: '1 result for "%{searchTerm}"',
              other: '%{count} results for "%{searchTerm}"',
            },
            {count: resultCount, searchTerm: query},
          )
    setScreenReader(message)
  }, [query, filteredEntries.length, loading, entries])

  const tableRows: Row[] = filteredEntries.map(item => ({
    relevance: item.relevance_ai_classification,
    name: item.student_name,
    notes: item.relevance_ai_evaluation_notes,
    date: formatDate(new Date(item.entry_updated_at)),
    actions: (
      <Flex gap="x-small" justifyItems="center">
        <Tooltip renderTip={I18n.t('See reply')}>
          <IconButton
            size="small"
            data-testid="viewOriginalReply"
            screenReaderLabel={I18n.t('See reply from %{user} on %{date}', {
              user: item.student_name,
              date: formatDate(new Date(item.entry_updated_at)),
            })}
            onClick={() => handleSeeReply(item)}
            withBackground={false}
            withBorder={false}
            color="primary"
          >
            <IconEyeLine />
          </IconButton>
        </Tooltip>
        {SPEEDGRADER_URL_TEMPLATE != null && (
          <Tooltip renderTip={I18n.t('See in SpeedGrader')}>
            <IconButton
              size="small"
              data-testid="viewSpeedGraderReply"
              screenReaderLabel={I18n.t('See in SpeedGrader')}
              href={SPEEDGRADER_URL_TEMPLATE?.replace(
                /%3Astudent_id/,
                String(item.student_id),
              ).concat(`&entry_id=${item.entry_id}&insight_entry_id=${item.id}`)}
              target="_blank"
              withBackground={false}
              withBorder={false}
              color="primary"
            >
              <IconSpeedGraderLine />
            </IconButton>
          </Tooltip>
        )}
        <Tooltip renderTip={I18n.t('See reply in context')}>
          <IconButton
            size="small"
            data-testid="goToOriginalReply"
            screenReaderLabel={I18n.t('Go to original reply')}
            href={`/courses/${contextId}/discussion_topics/${discussionId}?entry_id=${item.entry_id}`}
            target="_blank"
            withBackground={false}
            withBorder={false}
            color="primary"
            as="a"
          >
            <IconMoveDownBottomLine />
          </IconButton>
        </Tooltip>
      </Flex>
    ),
  }))

  if (!placeholderContent && !loading && filteredEntries.length === 0) {
    placeholderContent = <Placeholder type="no-results" />
  }

  return (
    <>
      <div aria-live="polite" aria-atomic="true">
        <ScreenReaderContent>{screenReader}</ScreenReaderContent>
      </div>
      <InsightsHeader />
      {insight?.needs_processing && <NewActivityInfo />}
      <InsightsActionBar
        loading={loading || ['created', 'in_progress'].includes(insight?.workflow_state || '')}
        entryCount={entryCount}
        onSearch={handleSearch}
        onGenerateInsights={handleGenerateInsights}
      />
      {!loading &&
        !['created', 'in_progress'].includes(insight?.workflow_state || '') &&
        !!entryCount &&
        !!filteredEntries.length && (
          <View as="div" margin="0 0 medium 0">
            <Text color="secondary" data-testid="insight-result-counter">
              {searchResultsText}
            </Text>
          </View>
        )}
      {placeholderContent}
      {!loading && !placeholderContent && !filteredEntries.length && (
        <Placeholder type="no-results" />
      )}
      {!loading && !placeholderContent && !!entryCount && filteredEntries?.length > 0 && (
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
