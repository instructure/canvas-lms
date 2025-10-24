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

import {
  mockUseLtiAssetProcessors,
  mockUseLtiAssetReports,
} from '../../../__tests__/mockedDependenciesShims'
import {renderHook} from '../../../__tests__/renderingShims'
import {clearAllMocks, describe, expect, it} from '../../../__tests__/testPlatformShims'
import {useLtiAssetReports} from '../../../dependenciesShims'
import {defaultGetLtiAssetProcessorsResult} from '../../__fixtures__/default/ltiAssetProcessors'
import {defaultGetLtiAssetReportsResult} from '../../__fixtures__/default/ltiAssetReports'
import {
  type UseLtiAssetProcessorsAndReportsForSpeedgraderParams,
  useLtiAssetProcessorsAndReportsForSpeedgrader,
} from '../useLtiAssetProcessorsAndReportsForSpeedgrader'

describe('useLtiAssetProcessorsAndReportsForSpeedgrader', () => {
  const mockParams: UseLtiAssetProcessorsAndReportsForSpeedgraderParams = {
    assignmentId: 'assignment-123',
    submissionType: 'online_upload',
    studentAnonymousId: 'student-123',
    studentUserId: null,
  }

  beforeEach(() => {
    clearAllMocks()
  })

  describe('basic functionality', () => {
    it('should return undefined when no processors are available', () => {
      mockUseLtiAssetProcessors({
        assignment: {
          ltiAssetProcessorsConnection: {
            nodes: [],
          },
        },
      })

      mockUseLtiAssetReports({
        submission: {ltiAssetReportsConnection: {nodes: []}},
      })

      const {result} = renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(result.current).toBeUndefined()
    })

    it('should return undefined when submission type is incompatible', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)

      mockUseLtiAssetReports(defaultGetLtiAssetReportsResult())

      const paramsWithIncompatibleType = {
        ...mockParams,
        submissionType: 'online_url', // incompatible type
      }

      const {result} = renderHook(() =>
        useLtiAssetProcessorsAndReportsForSpeedgrader(paramsWithIncompatibleType),
      )

      expect(result.current).toBeUndefined()
    })

    it('should return undefined when reports are not loaded', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(undefined)

      const {result} = renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(result.current).toBeUndefined()
    })

    it('should return data when processors and reports are available', () => {
      const reportsResult = defaultGetLtiAssetReportsResult()

      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(reportsResult)

      const {result} = renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(result.current).toEqual({
        assetProcessors:
          defaultGetLtiAssetProcessorsResult?.assignment?.ltiAssetProcessorsConnection?.nodes,
        assetReports: reportsResult?.submission?.ltiAssetReportsConnection?.nodes,
        compatibleSubmissionType: 'online_upload',
      })
    })
  })

  describe('query cancellation logic', () => {
    it('should cancel reports query when no processors are available', () => {
      mockUseLtiAssetProcessors({
        assignment: {
          ltiAssetProcessorsConnection: {
            nodes: [],
          },
        },
      })

      renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(useLtiAssetReports).toHaveBeenCalledWith(expect.any(Object), {
        cancel: true,
      })
    })

    it('should cancel reports query when submission type is incompatible', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)

      const paramsWithIncompatibleType = {
        ...mockParams,
        submissionType: 'online_url',
      }

      renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(paramsWithIncompatibleType))

      expect(useLtiAssetReports).toHaveBeenCalledWith(expect.any(Object), {
        cancel: true,
      })
    })

    it('should not cancel reports query when conditions are met', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(defaultGetLtiAssetReportsResult())

      renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(useLtiAssetReports).toHaveBeenCalledWith(expect.any(Object), {
        cancel: false,
      })
    })
  })

  describe('parameter handling', () => {
    it('should handle studentUserId parameter correctly', () => {
      const paramsWithUserId = {
        ...mockParams,
        studentUserId: 'user-123',
        studentAnonymousId: null,
      }

      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)

      renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(paramsWithUserId))

      expect(useLtiAssetReports).toHaveBeenCalledWith(
        {
          assignmentId: 'assignment-123',
          studentAnonymousId: null,
          studentUserId: 'user-123',
        },
        expect.any(Object),
      )
    })

    it('should handle studentAnonymousId parameter correctly', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)

      renderHook(() => useLtiAssetProcessorsAndReportsForSpeedgrader(mockParams))

      expect(useLtiAssetReports).toHaveBeenCalledWith(
        {
          assignmentId: 'assignment-123',
          studentAnonymousId: 'student-123',
          studentUserId: null,
        },
        expect.any(Object),
      )
    })
  })
})
