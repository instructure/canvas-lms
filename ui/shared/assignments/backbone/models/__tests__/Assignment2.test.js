/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import fakeENV from '@canvas/test-utils/fakeENV'
import Assignment from '../Assignment'
import Submission from '../Submission'

describe('Assignment', () => {
  describe('basic properties', () => {
    describe('unlockAt', () => {
      it('sets the record unlock_at as a setter', () => {
        const date = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.set('unlock_at', null)
        assignment.unlockAt(date)
        expect(assignment.unlockAt()).toBe(date)
      })
    })

    describe('lockAt', () => {
      it('gets the records lock_at as a getter', () => {
        const date = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.set('lock_at', date)
        expect(assignment.lockAt()).toBe(date)
      })

      it('sets the record lock_at as a setter', () => {
        const date = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.set('unlock_at', null)
        assignment.lockAt(date)
        expect(assignment.lockAt()).toBe(date)
      })
    })

    describe('description', () => {
      it('returns the record description as a getter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('description', 'desc')
        expect(assignment.description()).toBe('desc')
      })

      it('sets the record description as a setter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('description', null)
        assignment.description('desc')
        expect(assignment.description()).toBe('desc')
        expect(assignment.get('description')).toBe('desc')
      })
    })

    describe('dueDateRequired', () => {
      it('returns the record dueDateRequired as a getter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('dueDateRequired', true)
        expect(assignment.dueDateRequired()).toBe(true)
      })

      it('sets the record dueDateRequired as a setter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('dueDateRequired', null)
        assignment.dueDateRequired(true)
        expect(assignment.dueDateRequired()).toBe(true)
        expect(assignment.get('dueDateRequired')).toBe(true)
      })
    })

    describe('name', () => {
      it('returns the record name as a getter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('name', 'Todd')
        expect(assignment.name()).toBe('Todd')
      })

      it('sets the record name as a setter', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('name', 'NotTodd')
        assignment.name('Todd')
        expect(assignment.get('name')).toBe('Todd')
      })
    })

    describe('pointsPossible', () => {
      it('sets the record points_possible', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('points_possible', 0)
        assignment.pointsPossible(12)
        expect(assignment.pointsPossible()).toBe(12)
        expect(assignment.get('points_possible')).toBe(12)
      })
    })

    describe('secureParams', () => {
      it('returns secure params if set', () => {
        const secure_params = 'eyJ0eXAiOiJKV1QiLCJhb.asdf232.asdf2334'
        const assignment = new Assignment({name: 'foo'})
        assignment.set('secure_params', secure_params)
        expect(assignment.secureParams()).toBe(secure_params)
      })
    })

    describe('assignmentGroupId', () => {
      it('sets the record assignment group id', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('assignment_group_id', 0)
        assignment.assignmentGroupId(12)
        expect(assignment.assignmentGroupId()).toBe(12)
        expect(assignment.get('assignment_group_id')).toBe(12)
      })
    })

    describe('gradingType', () => {
      it('sets the record grading type', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('grading_type', 'points')
        assignment.gradingType('percent')
        expect(assignment.gradingType()).toBe('percent')
        expect(assignment.get('grading_type')).toBe('percent')
      })
    })
  })

  describe('permissions and state', () => {
    describe('canDelete', () => {
      beforeEach(() => {
        fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('returns false if frozen is true', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('frozen', true)
        expect(assignment.canDelete()).toBe(false)
      })

      it('returns false if in_closed_grading_period is true', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('in_closed_grading_period', true)
        expect(assignment.canDelete()).toBe(false)
      })

      it('returns true if frozen and in_closed_grading_period are false', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('frozen', false)
        assignment.set('in_closed_grading_period', false)
        expect(assignment.canDelete()).toBe(true)
      })
    })

    describe('canMove', () => {
      describe('as teacher', () => {
        beforeEach(() => {
          fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
        })

        afterEach(() => {
          fakeENV.teardown()
        })

        it('returns false if grading period is closed', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', true)
          expect(assignment.canMove()).toBe(false)
        })

        it('returns false if grading period not closed but group id is locked', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', false)
          assignment.set('in_closed_grading_period', ['assignment_group_id'])
          expect(assignment.canMove()).toBe(false)
        })

        it('returns true if grading period not closed and group id is not locked', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', false)
          expect(assignment.canMove()).toBe(true)
        })
      })

      describe('as admin', () => {
        beforeEach(() => {
          fakeENV.setup({current_user_is_admin: true})
        })

        afterEach(() => {
          fakeENV.teardown()
        })

        it('returns true if grading period is closed', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', true)
          expect(assignment.canMove()).toBe(true)
        })

        it('returns true if grading period not closed but group id is locked', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', false)
          assignment.set('in_closed_grading_period', ['assignment_group_id'])
          expect(assignment.canMove()).toBe(true)
        })

        it('returns true if grading period not closed and group id is not locked', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', false)
          expect(assignment.canMove()).toBe(true)
        })
      })
    })

    describe('inClosedGradingPeriod', () => {
      describe('as non admin', () => {
        beforeEach(() => {
          fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
        })

        afterEach(() => {
          fakeENV.teardown()
        })

        it('returns the value of in_closed_grading_period when isAdmin is false', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', true)
          expect(assignment.inClosedGradingPeriod()).toBe(true)
          assignment.set('in_closed_grading_period', false)
          expect(assignment.inClosedGradingPeriod()).toBe(false)
        })
      })

      describe('as admin', () => {
        beforeEach(() => {
          fakeENV.setup({current_user_is_admin: true})
        })

        afterEach(() => {
          fakeENV.teardown()
        })

        it('returns false when isAdmin is true', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('in_closed_grading_period', true)
          expect(assignment.inClosedGradingPeriod()).toBe(false)
          assignment.set('in_closed_grading_period', false)
          expect(assignment.inClosedGradingPeriod()).toBe(false)
        })
      })
    })
  })

  describe('submission handling', () => {
    describe('submissionType', () => {
      it("returns 'none' if record submission_types is ['none']", () => {
        const assignment = new Assignment({
          name: 'foo',
          id: '12',
        })
        assignment.set('submission_types', ['none'])
        expect(assignment.submissionType()).toBe('none')
      })

      it("returns 'on_paper' if record submission_types includes on_paper", () => {
        const assignment = new Assignment({
          name: 'foo',
          id: '13',
        })
        assignment.set('submission_types', ['on_paper'])
        expect(assignment.submissionType()).toBe('on_paper')
      })

      it('returns online submission otherwise', () => {
        const assignment = new Assignment({
          name: 'foo',
          id: '14',
        })
        assignment.set('submission_types', ['online_upload'])
        expect(assignment.submissionType()).toBe('online')
      })
    })

    describe('expectsSubmission', () => {
      it('returns false if assignment submission type is not online', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({
          submission_types: ['external_tool', 'on_paper'],
        })
        expect(assignment.expectsSubmission()).toBe(false)
      })

      it('returns true if an assignment submission type is online', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission_types: ['online']})
        expect(assignment.expectsSubmission()).toBe(true)
      })
    })

    describe('allowedToSubmit', () => {
      it('returns false if assignment is locked', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission_types: ['online']})
        assignment.set({locked_for_user: true})
        expect(assignment.allowedToSubmit()).toBe(false)
      })

      it('returns true if an assignment is not locked', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission_types: ['online']})
        assignment.set({locked_for_user: false})
        expect(assignment.allowedToSubmit()).toBe(true)
      })

      it('returns false if a submission is not expected', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({
          submission_types: ['external_tool', 'on_paper', 'attendance'],
        })
        expect(assignment.allowedToSubmit()).toBe(false)
      })
    })

    describe('withoutGradedSubmission', () => {
      it('returns false if there is a submission', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission: new Submission({submission_type: 'online'})})
        expect(assignment.withoutGradedSubmission()).toBe(false)
      })

      it('returns true if there is no submission', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission: null})
        expect(assignment.withoutGradedSubmission()).toBe(true)
      })

      it('returns true if there is a submission, but no grade', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission: new Submission()})
        expect(assignment.withoutGradedSubmission()).toBe(true)
      })

      it('returns false if there is a submission and a grade', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set({submission: new Submission({grade: 305})})
        expect(assignment.withoutGradedSubmission()).toBe(false)
      })
    })

    describe('submission type flags', () => {
      describe('acceptsOnlineUpload', () => {
        it('returns true if record submission types includes online_upload', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', ['online_upload'])
          expect(assignment.acceptsOnlineUpload()).toBe(true)
        })

        it("returns false if submission types doesn't include online_upload", () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', [])
          expect(assignment.acceptsOnlineUpload()).toBe(false)
        })
      })

      describe('acceptsOnlineURL', () => {
        it('returns true if assignment allows online url', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', ['online_url'])
          expect(assignment.acceptsOnlineURL()).toBe(true)
        })

        it("returns false if submission types doesn't include online_url", () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', [])
          expect(assignment.acceptsOnlineURL()).toBe(false)
        })
      })

      describe('acceptsMediaRecording', () => {
        it('returns true if submission types includes media recordings', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', ['media_recording'])
          expect(assignment.acceptsMediaRecording()).toBe(true)
        })
      })

      describe('acceptsOnlineTextEntries', () => {
        it('returns true if submission types includes online text entry', () => {
          const assignment = new Assignment({name: 'foo'})
          assignment.set('submission_types', ['online_text_entry'])
          expect(assignment.acceptsOnlineTextEntries()).toBe(true)
        })
      })
    })
  })
})
