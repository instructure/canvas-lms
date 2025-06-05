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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import DiscussionInsights from '../DiscussionInsights'
import useInsightStore from '../../../hooks/useInsightStore'
import {useInsight} from '../../../hooks/useFetchInsights'

jest.mock('../../../hooks/useInsightStore')
const mockedUseInsightStore = useInsightStore as unknown as jest.Mock

jest.mock('../../../hooks/useFetchInsights')
const mockedUseInsight = useInsight as jest.Mock

describe('DiscussionInsights', () => {
  beforeEach(() => {
    const mockState = {
      context: 'test-context',
      contextId: 'test-context-id',
      discussionId: 'test-discussion-id',
      filterType: 'all',
      setModalOpen: jest.fn(),
      genereteInsight: jest.fn(),
      setEntryId: jest.fn(),
      setEntries: jest.fn(),
      setFeedbackNotes: jest.fn(),
      setFilterType: jest.fn(),
      setIsFilteredTable: jest.fn(),
      openEvaluationModal: jest.fn(),
    }
    mockedUseInsightStore.mockImplementation(selector => selector(mockState))
  })

  it('displays loading placeholder when loading', () => {
    mockedUseInsight.mockReturnValue({
      loading: true,
      insight: null,
      insightError: null,
      entries: undefined,
    })

    render(<DiscussionInsights />)
    expect(screen.getByText('Loading')).toBeInTheDocument()
  })

  it('displays error placeholder when there is an error loading the insight', () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: null,
      insightError: true,
      entries: null,
    })

    render(<DiscussionInsights />)
    expect(screen.getByText('There was an error loading the insights')).toBeInTheDocument()
  })

  it('displays the error placeholder if the generation failed', () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: {workflow_state: 'failed'},
      insightError: null,
      entries: null,
    })

    render(<DiscussionInsights />)
    expect(screen.getByText('There was an error generating the insights')).toBeInTheDocument()
  })

  it('displays no replies placeholder when there is no reply on the discussion', () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: {workflow_state: 'completed'},
      insightError: null,
      entries: [],
      entryCount: 0,
    })

    render(<DiscussionInsights />)
    expect(screen.getByText('There are no replies for this topic yet')).toBeInTheDocument()
  })

  it('displays no insight if it is not yet generated', () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: {workflow_state: null},
      insightError: null,
      entries: null,
    })

    render(<DiscussionInsights />)
    expect(screen.getByText('You haven’t generated any insights yet')).toBeInTheDocument()
  })

  it('displays no results placeholder when there are no filtered entries', async () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: {workflow_state: 'completed'},
      insightError: null,
      entries: [{student_name: 'John Doe'}],
    })

    render(<DiscussionInsights />)
    const searchInput = screen.getByPlaceholderText('Search...')
    fireEvent.change(searchInput, {target: {value: 'Jane'}})

    await waitFor(() => {
      expect(screen.getByText('No results found')).toBeInTheDocument()
    })
  })

  it('displays info alert when there are new replies', () => {
    mockedUseInsight.mockReturnValue({
      loading: false,
      insight: {workflow_state: 'completed', needs_processing: true},
      insightError: null,
      entries: [{student_name: 'John Doe'}],
    })

    render(<DiscussionInsights />)
    expect(
      screen.getByText(
        'The discussion board has some new activity since the last insights were generated.',
      ),
    ).toBeInTheDocument()
  })
})
