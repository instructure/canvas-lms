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

import {Submission} from '../../assignments_show_student'
import {WORKFLOW_STATES, SUBMISSION_STATES} from '../constants/submissionStates'

describe('Submission Workflow States', () => {
  describe('SUBMISSION_STATES', () => {
    it('defines all required states', () => {
      expect(SUBMISSION_STATES).toEqual({
        IN_PROGRESS: 'inProgress',
        SUBMITTED: 'submitted',
        COMPLETED: 'completed',
      })
    })
  })

  describe('WORKFLOW_STATES', () => {
    it('defines states for all submission states', () => {
      Object.values(SUBMISSION_STATES).forEach(state => {
        expect(WORKFLOW_STATES[state]).toBeDefined()
      })
    })

    it('provides correct structure for IN_PROGRESS state', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.IN_PROGRESS]
      expect(state.value).toBe(1)
      expect(state.title).toBeDefined()
      expect(state.subtitle).toBe('NEXT UP: Submit Assignment')
    })

    it('provides correct structure for SUBMITTED state', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED]
      expect(state.value).toBe(2)
      expect(typeof state.title).toBe('function')
      expect(state.subtitle).toBe('NEXT UP: Review Feedback')
    })

    it('provides correct structure for COMPLETED state', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.COMPLETED]
      expect(state.value).toBe(3)
      expect(state.title).toBeDefined()
      expect(typeof state.subtitle).toBe('function')
    })

    it('handles submitted state title correctly', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED]
      const submission = {
        submittedAt: '2025-05-29T10:00:00Z',
      } as Submission
      let titleElement
      if (typeof state.title === 'function') {
        titleElement = state.title(submission)
      } else {
        titleElement = state.title
      }
      expect(titleElement).toBeDefined()
      expect(titleElement.props.dateTime).toBe(submission.submittedAt)
    })

    it('handles completed state subtitle correctly', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.COMPLETED]
      const submission = {
        attempt: 1,
        submittedAt: '2025-05-29T10:00:00Z',
      }
      const subtitleElement = state.subtitle(submission)
      expect(subtitleElement).toBeDefined()
      expect(subtitleElement.props.dateTime).toBe(submission.submittedAt)
    })

    it('returns null for completed state subtitle when attempt is 0', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.COMPLETED]
      const submission = {
        attempt: 0,
        submittedAt: '2025-05-29T10:00:00Z',
      }
      expect(state.subtitle(submission)).toBeNull()
    })

    it('returns completion message when submittedAt is null', () => {
      const state = WORKFLOW_STATES[SUBMISSION_STATES.COMPLETED]
      const submission = {
        attempt: 1,
        submittedAt: null,
      }
      expect(state.subtitle(submission)).toBe('This assignment is complete!')
    })
  })
})
