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
import {act, waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import {useContributingScores, ContributingScoresResponse} from '../useContributingScores'

describe('useContributingScores', () => {
  const courseId = '1'
  const studentIds = ['6', '7']
  const outcomeIds = ['2', '3']

  const mockContributingScoresOutcome2: ContributingScoresResponse = {
    outcome: {
      id: '2',
      title: '123 SCND OUTC',
    },
    alignments: [
      {
        alignment_id: 'D_5',
        associated_asset_id: '2',
        associated_asset_name: 'r2',
        associated_asset_type: 'Rubric',
        html_url: 'http://canvas-web.inseng.test/courses/1/rubrics/2',
      },
      {
        alignment_id: 'D_6',
        associated_asset_id: '2',
        associated_asset_name: 'a2',
        associated_asset_type: 'Assignment',
        html_url: 'http://canvas-web.inseng.test/courses/1/assignments/2',
      },
    ],
    scores: [
      {
        user_id: '6',
        alignment_id: 'D_6',
        score: 1,
      },
      {
        user_id: '7',
        alignment_id: 'D_5',
        score: 3,
      },
      {
        user_id: '7',
        alignment_id: 'D_6',
        score: 2,
      },
    ],
  }

  const mockContributingScoresOutcome3: ContributingScoresResponse = {
    outcome: {
      id: '3',
      title: 'Third Outcome',
    },
    alignments: [
      {
        alignment_id: 'D_7',
        associated_asset_id: '3',
        associated_asset_name: 'a3',
        associated_asset_type: 'Assignment',
        html_url: 'http://canvas-web.inseng.test/courses/1/assignments/3',
      },
    ],
    scores: [
      {
        user_id: '6',
        alignment_id: 'D_7',
        score: 5,
      },
    ],
  }

  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const Wrapper: React.FC<any> = ({children}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('initial state', () => {
    it('returns initial state with no visible outcomes', () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeNull()
      expect(result.current.contributingScores).toBeDefined()
    })

    it('outcomes are not visible by default', () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const outcome1 = result.current.contributingScores.forOutcome('2')
      const outcome2 = result.current.contributingScores.forOutcome('3')

      expect(outcome1.isVisible()).toBe(false)
      expect(outcome2.isVisible()).toBe(false)
    })

    it('does not make API calls when outcomes are not visible', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })
  })

  describe('toggleVisibility', () => {
    it('toggles outcome visibility on', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      expect(result.current.contributingScores.forOutcome('2').isVisible()).toBe(false)

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      expect(result.current.contributingScores.forOutcome('2').isVisible()).toBe(true)
    })

    it('toggles outcome visibility off', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      expect(result.current.contributingScores.forOutcome('2').isVisible()).toBe(true)

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      expect(result.current.contributingScores.forOutcome('2').isVisible()).toBe(false)
    })
  })

  describe('data fetching', () => {
    it('fetches data when outcome visibility is toggled on', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').isLoading).toBe(false)
      })

      expect(fetchMock.calls()).toHaveLength(1)
      expect(result.current.contributingScores.forOutcome('2').data).toEqual(
        mockContributingScoresOutcome2,
      )
    })

    it('fetches data for multiple visible outcomes', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/3/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome3,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
        result.current.contributingScores.forOutcome('3').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').isLoading).toBe(false)
        expect(result.current.contributingScores.forOutcome('3').isLoading).toBe(false)
      })

      expect(fetchMock.calls()).toHaveLength(2)
      expect(result.current.contributingScores.forOutcome('2').data).toEqual(
        mockContributingScoresOutcome2,
      )
      expect(result.current.contributingScores.forOutcome('3').data).toEqual(
        mockContributingScoresOutcome3,
      )
    })

    it('returns alignments from fetched data', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').alignments).toBeDefined()
      })

      expect(result.current.contributingScores.forOutcome('2').alignments).toEqual(
        mockContributingScoresOutcome2.alignments,
      )
    })
  })

  describe('scoresForUser', () => {
    it('returns empty array when no data is loaded', () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const scores = result.current.contributingScores.forOutcome('2').scoresForUser('6')
      expect(scores).toEqual([])
    })

    it('returns score strings for each alignment', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').data).toBeDefined()
      })

      const scoresForUser6 = result.current.contributingScores.forOutcome('2').scoresForUser('6')
      // User 6 has no score for D_5 (undefined) and score 1 for D_6
      expect(scoresForUser6).toEqual([undefined, 1])

      const scoresForUser7 = result.current.contributingScores.forOutcome('2').scoresForUser('7')
      // User 7 has score 3 for D_5 and score 2 for D_6
      expect(scoresForUser7).toEqual([3, 2])
    })

    it('returns undefined for alignments without scores', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').data).toBeDefined()
      })

      // User 8 has no scores
      const scoresForUser8 = result.current.contributingScores.forOutcome('2').scoresForUser('8')
      expect(scoresForUser8).toEqual([undefined, undefined])
    })
  })

  describe('error handling', () => {
    it('handles API error', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        {
          status: 500,
          body: {error: 'Internal server error'},
        },
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').error).toBeTruthy()
      })

      expect(result.current.error).toBeTruthy()
    })

    it('handles network error', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        {
          throws: new Error('Network error'),
        },
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').error).toBeTruthy()
      })
    })
  })

  describe('enabled parameter', () => {
    it('does not fetch when enabled is false', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: false}),
        {wrapper: createWrapper()},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('does not fetch when studentIds is empty', async () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds: [], outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      fetchMock.get(/.*/, mockContributingScoresOutcome2)

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })
  })

  describe('refetching on studentIds change', () => {
    it('refetches data when studentIds change', async () => {
      const {result, rerender} = renderHook(
        ({ids}: {ids: string[]}) =>
          useContributingScores({courseId, studentIds: ids, outcomeIds, enabled: true}),
        {
          wrapper: createWrapper(),
          initialProps: {ids: ['6']},
        },
      )

      let userIdsParams = ['6'].map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result.current.contributingScores.forOutcome('2').data).toBeDefined()
      })

      expect(fetchMock.calls()).toHaveLength(1)

      // Change studentIds
      userIdsParams = ['6', '7'].map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
        {overwriteRoutes: false},
      )

      rerender({ids: ['6', '7']})

      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(2)
      })
    })
  })

  describe('caching behavior', () => {
    it('caches data for 5 minutes (staleTime)', async () => {
      const wrapper = createWrapper()

      const {result: result1} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper},
      )

      const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcomes/2/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
        mockContributingScoresOutcome2,
      )

      act(() => {
        result1.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result1.current.contributingScores.forOutcome('2').data).toBeDefined()
      })

      expect(fetchMock.calls()).toHaveLength(1)

      // Second render with same params should use cache
      const {result: result2} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper},
      )

      act(() => {
        result2.current.contributingScores.forOutcome('2').toggleVisibility()
      })

      await waitFor(() => {
        expect(result2.current.contributingScores.forOutcome('2').data).toBeDefined()
      })

      // Should still only have 1 API call (cached)
      expect(fetchMock.calls()).toHaveLength(1)
    })
  })

  describe('edge cases', () => {
    it('handles outcome not in outcomeIds list', () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds, enabled: true}),
        {wrapper: createWrapper()},
      )

      const unknownOutcome = result.current.contributingScores.forOutcome('999')

      expect(unknownOutcome.isVisible()).toBe(false)
      expect(unknownOutcome.data).toBeUndefined()
      expect(unknownOutcome.scoresForUser('6')).toEqual([])
    })

    it('handles empty outcomeIds array', () => {
      const {result} = renderHook(
        () => useContributingScores({courseId, studentIds, outcomeIds: [], enabled: true}),
        {wrapper: createWrapper()},
      )

      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeNull()
    })
  })
})
