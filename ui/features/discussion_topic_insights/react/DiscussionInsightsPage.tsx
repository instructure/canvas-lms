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
import LoadingIndicator from '@canvas/loading-indicator'
import DiscussionInsights from './components/DiscussionInsights/DiscussionInsights'
import {Button} from '@instructure/ui-buttons'
import ReviewModal from './components/ReviewModal/ReviewModal'
import InsightsReviewRatings from './components/InsightsReviewRatings/InsightsReviewRatings'
import {getStatusByRelevance, formatDate} from './utils'
import {useGetInsights} from './hooks/useFetchInsights'
import {Header, Row} from './components/InsightsTable/SimpleTable'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

type DiscussionInsightsProps = {
  context: string
  contextId: string
  discussionId: string
}

const DiscussionInsightsPage: React.FC<DiscussionInsightsProps> = ({
  context,
  contextId,
  discussionId,
}) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const {data, error, isLoading} = useGetInsights(context, contextId, discussionId)

  if (isLoading) {
    return <LoadingIndicator />
  }
  if (error) {
    throw error
  }

  const handleSeeReply = () => {
    setIsModalOpen(true)
  }

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

  const rows: Row[] = data.map((item: any, index: number) => ({
    relevance: getStatusByRelevance(
      item.relevance_ai_classification,
      item.relevance_ai_classification_confidence,
    ),
    name: item.student_name,
    notes: item.relevance_ai_evaluation_notes,
    review: <InsightsReviewRatings />,
    date: formatDate(new Date(item.entry_updated_at)),
    actions: (
      <Button size="small" onClick={handleSeeReply}>
        {I18n.t('See Reply')}
      </Button>
    ),
  }))

  return (
    <>
      <ReviewModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
      <DiscussionInsights headers={headers} rows={rows} />
    </>
  )
}

export default DiscussionInsightsPage
