/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import DueDateOverrideView from '../DueDateOverride'
import * as assignToHelper from '../../../../context-modules/differentiated-modules/utils/assignToHelper'

jest.mock('../../../../context-modules/differentiated-modules/utils/assignToHelper')

describe('DueDateOverrideView', () => {
  let view
  let mockModel
  let mockOverrides

  beforeEach(() => {
    mockOverrides = {
      reset: jest.fn(),
      containsDefaultDueDate: jest.fn().mockReturnValue(false),
    }

    mockModel = {
      assignment: {
        get: jest.fn(),
        set: jest.fn(),
        isOnlyVisibleToOverrides: jest.fn(),
        importantDates: jest.fn(),
      },
      overrides: mockOverrides,
    }

    view = new DueDateOverrideView({
      model: mockModel,
    })

    window.ENV = window.ENV || {}
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('setNewOverridesCollection', () => {
    const newOverrides = [{id: '1', due_at: '2025-01-15'}]
    const importantDates = true

    describe('when peer reviews are disabled', () => {
      beforeEach(() => {
        mockModel.assignment.get.mockReturnValue(false)
      })

      it('calls resetOverrides with newOverrides directly', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockOverrides.reset).toHaveBeenCalledWith(newOverrides)
        expect(mockModel.assignment.importantDates).toHaveBeenCalledWith(importantDates)
      })

      it('does not call getAssignmentAndPeerReviewOverrides', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(assignToHelper.getAssignmentAndPeerReviewOverrides).not.toHaveBeenCalled()
      })
    })

    describe('when peer reviews are enabled but feature flag is disabled', () => {
      beforeEach(() => {
        mockModel.assignment.get.mockReturnValue(true)
        window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
      })

      it('calls resetOverrides with newOverrides directly', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockOverrides.reset).toHaveBeenCalledWith(newOverrides)
        expect(mockModel.assignment.importantDates).toHaveBeenCalledWith(importantDates)
      })

      it('does not call getAssignmentAndPeerReviewOverrides', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(assignToHelper.getAssignmentAndPeerReviewOverrides).not.toHaveBeenCalled()
      })

      it('does not set peer_review_data on the assignment', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockModel.assignment.set).not.toHaveBeenCalledWith(
          'peer_review_data',
          expect.anything(),
        )
      })
    })

    describe('when peer reviews are enabled and feature flag is enabled', () => {
      const assignmentOverrides = [{id: '1', due_at: '2025-01-15'}]
      const peerReviewData = {
        due_at: '2025-01-20',
        unlock_at: '2025-01-10',
        lock_at: '2025-01-25',
      }

      beforeEach(() => {
        mockModel.assignment.get.mockReturnValue(true)
        window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = true
        assignToHelper.getAssignmentAndPeerReviewOverrides.mockReturnValue({
          assignmentOverrides,
          peerReview: peerReviewData,
        })
      })

      it('calls getAssignmentAndPeerReviewOverrides with newOverrides', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(assignToHelper.getAssignmentAndPeerReviewOverrides).toHaveBeenCalledWith(
          newOverrides,
        )
      })

      it('calls resetOverrides with assignmentOverrides only', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockOverrides.reset).toHaveBeenCalledWith(assignmentOverrides)
        expect(mockModel.assignment.importantDates).toHaveBeenCalledWith(importantDates)
      })

      it('sets peer_review_data on the assignment when peerReview data exists', () => {
        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockModel.assignment.set).toHaveBeenCalledWith('peer_review_data', peerReviewData)
      })

      it('does not set peer_review_data when peerReview is empty', () => {
        assignToHelper.getAssignmentAndPeerReviewOverrides.mockReturnValue({
          assignmentOverrides,
          peerReview: {},
        })

        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockModel.assignment.set).not.toHaveBeenCalledWith(
          'peer_review_data',
          expect.anything(),
        )
      })

      it('does not set peer_review_data when peerReview is undefined', () => {
        assignToHelper.getAssignmentAndPeerReviewOverrides.mockReturnValue({
          assignmentOverrides,
          peerReview: undefined,
        })

        view.setNewOverridesCollection(newOverrides, importantDates)

        expect(mockModel.assignment.set).not.toHaveBeenCalledWith(
          'peer_review_data',
          expect.anything(),
        )
      })
    })
  })
})
