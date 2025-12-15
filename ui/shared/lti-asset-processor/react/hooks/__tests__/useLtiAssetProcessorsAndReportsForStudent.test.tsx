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

import {act, renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {
  useLtiAssetProcessorsAndReportsForStudent,
  useShouldShowLtiAssetReportsForStudent,
  type AssetReportsForStudentParams,
} from '../useLtiAssetProcessorsAndReportsForStudent'
import {defaultGetLtiAssetProcessorsAndReportsForStudentResult} from '../../../queries/__fixtures__/LtiAssetProcessorsAndReportsForStudent'
import {executeQueryAndValidate} from '../graphqlQueryHooks'
import {ZGetLtiAssetProcessorsAndReportsForStudentResult} from '@canvas/lti-asset-processor/queries/getLtiAssetProcessorsAndReportsForStudent'
import {waitFor} from '@testing-library/react'

vi.mock('../graphqlQueryHooks', () => ({
  executeQueryAndValidate: vi.fn(() =>
    Promise.resolve(defaultGetLtiAssetProcessorsAndReportsForStudentResult()),
  ),
}))

const mockExecuteQueryAndValidate = executeQueryAndValidate as ReturnType<typeof vi.fn>

let queryClient: QueryClient

const createWrapper = () => {
  queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

let originalEnv: typeof window.ENV

describe('useLtiAssetProcessorsAndReportsForStudent hooks', () => {
  let defaultSubmission: AssetReportsForStudentParams

  beforeEach(() => {
    originalEnv = window.ENV
    defaultSubmission = {
      submissionId: 'submission-123',
      submissionType: 'online_upload',
    }
    window.ENV = {
      ...originalEnv,
      FEATURES: {lti_asset_processor: true},
    }
    vi.clearAllMocks()
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  function renderShouldShow() {
    return renderHook(() => useShouldShowLtiAssetReportsForStudent(defaultSubmission), {
      wrapper: createWrapper(),
    })
  }

  function renderMainHook(attachmentId?: string) {
    return renderHook(
      () => useLtiAssetProcessorsAndReportsForStudent({...defaultSubmission, attachmentId}),
      {
        wrapper: createWrapper(),
      },
    )
  }

  async function waitUntilIdle() {
    await waitFor(() => {
      const query = queryClient.getQueryState([
        'ltiAssetProcessorsAndReportsForStudent',
        'submission-123',
      ])
      expect(query?.fetchStatus).toEqual('idle')
    })
    // For good measure, wait a tick for any state updates:
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 1))
    })
  }

  describe('query behavior', () => {
    it('does not call executeQueryAndValidate when feature flag is disabled', async () => {
      window.ENV = {...originalEnv, FEATURES: {lti_asset_processor: false}}

      renderMainHook()
      await waitUntilIdle()

      expect(mockExecuteQueryAndValidate).not.toHaveBeenCalled()
    })

    it('does not call executeQueryAndValidate when submission type is incompatible', async () => {
      const incompatibleSubmission: AssetReportsForStudentParams = {
        submissionId: 'submission-123',
        submissionType: 'on_paper', // Not compatible with asset processing
      }

      renderHook(() => useLtiAssetProcessorsAndReportsForStudent(incompatibleSubmission), {
        wrapper: createWrapper(),
      })
      await waitUntilIdle()

      expect(mockExecuteQueryAndValidate).not.toHaveBeenCalled()
    })
  })

  describe('useShouldShowLtiAssetReportsForStudent', () => {
    it('returns true if there is data', async () => {
      const {result} = renderShouldShow()
      await waitUntilIdle()

      expect(result.current).toBe(true)
    })

    it('returns false when no data is available', async () => {
      const data = defaultGetLtiAssetProcessorsAndReportsForStudentResult()
      data!.submission!.assignment!.ltiAssetProcessorsConnection!.nodes = []
      data!.submission!.ltiAssetReportsConnection!.nodes = []
      mockExecuteQueryAndValidate.mockResolvedValueOnce(data)

      const {result} = renderShouldShow()

      await waitUntilIdle()

      expect(result.current).toBe(false)
    })

    it('returns false when feature flag is disabled', async () => {
      window.ENV = {...originalEnv, FEATURES: {lti_asset_processor: false}}

      const {result} = renderShouldShow()
      await waitUntilIdle()

      expect(result.current).toBe(false)
      expect(mockExecuteQueryAndValidate).not.toHaveBeenCalled()
    })

    it('returns false if submission type is incompatible', async () => {
      const nullSubmissionTypeSubmission: AssetReportsForStudentParams = {
        submissionId: 'submission-123',
        submissionType: 'none',
      }

      const {result} = renderHook(
        () => useShouldShowLtiAssetReportsForStudent(nullSubmissionTypeSubmission),
        {wrapper: createWrapper()},
      )
      await waitUntilIdle()

      expect(result.current).toBe(false)
      expect(mockExecuteQueryAndValidate).not.toHaveBeenCalled()
    })

    it('returns true if ifLastAttemptIsNumber matches the attempt in the query response', async () => {
      defaultSubmission.ifLastAttemptIsNumber = 1
      const {result} = renderShouldShow()
      await waitUntilIdle()

      expect(result.current).toBe(true)
    })

    it("returns false if ifLastAttemptIsNumber doesn't match the attempt in the query response", async () => {
      defaultSubmission.ifLastAttemptIsNumber = 2
      const {result} = renderShouldShow()
      await waitUntilIdle()

      expect(result.current).toBe(false)
    })
  })

  describe('useLtiAssetProcessorsAndReportsForStudent attachment filtering', () => {
    it('tests attachment filtering logic when provided', async () => {
      const data = defaultGetLtiAssetProcessorsAndReportsForStudentResult()
      data!.submission!.ltiAssetReportsConnection!.nodes![0]!.asset = {
        attachmentId: 'very-special-cool-unique-id',
        attachmentName: 'foo',
      }

      mockExecuteQueryAndValidate.mockResolvedValueOnce(data)
      const {result} = renderMainHook('very-special-cool-unique-id')
      await waitFor(() => {
        expect(result.current!.reports).toHaveLength(1)
      })
    })

    it('returns original data when no attachmentId is provided', async () => {
      const {result} = renderMainHook()
      await waitFor(() => {
        expect(result.current!.reports).toHaveLength(3)
      })
    })
  })

  describe('data fetching', () => {
    it('returns expected data from fixture after fetching', async () => {
      const {result, waitFor} = renderHook(
        () => useLtiAssetProcessorsAndReportsForStudent(defaultSubmission),
        {
          wrapper: createWrapper(),
        },
      )

      // Wait for the hook to fetch and return data
      await waitFor(() => {
        expect(result.current).toBeDefined()
      })

      // Verify the returned data matches what we expect from the fixture
      expect(result.current).toEqual({
        assignmentName: 'Test Assignment',
        attempt: 1,
        submissionType: 'online_upload',
        assetProcessors: expect.arrayContaining([
          expect.objectContaining({
            _id: expect.any(String),
            title: expect.any(String),
            externalTool: expect.objectContaining({
              name: expect.any(String),
            }),
          }),
        ]),
        reports: expect.arrayContaining([
          expect.objectContaining({
            _id: expect.any(String),
            title: expect.any(String),
            processorId: expect.any(String),
            processingProgress: expect.any(String),
          }),
        ]),
      })

      // Verify we have the expected number of items from the fixture
      expect(result.current!.assetProcessors).toHaveLength(2)
      expect(result.current!.reports).toHaveLength(3)

      // Verify that executeQueryAndValidate was called
      expect(mockExecuteQueryAndValidate).toHaveBeenCalledWith(
        expect.anything(), // The GraphQL query
        {submissionId: 'submission-123'},
        expect.any(String), // Error message
        ZGetLtiAssetProcessorsAndReportsForStudentResult,
      )
    })
  })
})
