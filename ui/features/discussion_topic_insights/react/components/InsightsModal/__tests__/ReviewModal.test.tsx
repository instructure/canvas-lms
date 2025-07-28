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

import React from 'react'
import {render, act} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import ReviewModal from '../ReviewModal'
import useInsightStore from '../../../hooks/useInsightStore'
import {useInsight, InsightEntry} from '../../../hooks/useFetchInsights'
import EvaluationFeedback from '../EvaluationFeedback'

jest.mock('../EvaluationFeedback', () => jest.fn(() => null))
const MockedEvaluationFeedback = EvaluationFeedback as jest.Mock

jest.mock('../../../hooks/useFetchInsights')
const mockedUseInsight = useInsight as jest.MockedFunction<typeof useInsight>

const entry1: InsightEntry = {
  id: 123,
  entry_content: "This is the student's contribution to the discussion.",
  entry_id: 456,
  entry_updated_at: '2025-05-19T08:30:00Z',
  student_id: 789,
  student_name: 'Jane Doe',
  relevance_ai_classification: 'relevant',
  relevance_ai_evaluation_notes: 'AI classified as relevant due to keywords X and Y.',
  relevance_human_reviewer: 101,
  relevance_human_feedback_liked: true,
  relevance_human_feedback_disliked: false,
  relevance_human_feedback_notes: 'Human reviewer agrees with AI. Good points raised.',
}

const getInitialTestState = () => ({
  context: 'test-context',
  contextId: 'test-context-id',
  discussionId: 'test-discussion-id',
  modalOpen: true,
  entryId: 123,
  entries: [entry1],
  feedbackNotes: '',
  filterType: 'all',
  isFilteredTable: false,
})

describe('ReviewModal', () => {
  beforeEach(() => {
    act(() => {
      useInsightStore.setState(getInitialTestState(), true)
    })
    MockedEvaluationFeedback.mockClear()
    mockedUseInsight.mockReset()
  })

  it('displays the modal', async () => {
    const setup = () => {
      return render(<ReviewModal />)
    }
    const {getByTestId} = setup()
    expect(getByTestId('reviewModal')).toBeInTheDocument()
  })

  it("sets trackable attributes correctly to 'See Reply in Context'", async () => {
    const setup = () => {
      return render(<ReviewModal />)
    }
    const {getByTestId} = setup()
    expect(getByTestId('seeReplyInContext')).toBeInTheDocument()
  })
})
