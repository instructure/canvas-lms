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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Assignment', () => {
  describe('#suppressAssignment', () => {
    let assignment
    beforeEach(() => {
      assignment = new Assignment()
      fakeENV.setup({current_user_roles: []})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('called with params', () => {
      expect(assignment.suppressAssignment()).toBe(undefined)
      assignment.suppressAssignment(true)
      expect(assignment.suppressAssignment()).toBe(true)
    })

    it('called without params', () => {
      expect(assignment.suppressAssignment()).toBe(undefined)
    })
  })

  describe('newQuizzesType', () => {
    it('returns "graded_quiz" by default when settings is not set', () => {
      const assignment = new Assignment()
      expect(assignment.newQuizzesType()).toBe('graded_quiz')
    })

    it('returns "graded_quiz" by default when settings.new_quizzes is not set', () => {
      const assignment = new Assignment({settings: {}})
      expect(assignment.newQuizzesType()).toBe('graded_quiz')
    })

    it('returns "graded_quiz" by default when settings.new_quizzes.type is not set', () => {
      const assignment = new Assignment({settings: {new_quizzes: {}}})
      expect(assignment.newQuizzesType()).toBe('graded_quiz')
    })

    it('returns the stored type when set', () => {
      const assignment = new Assignment({
        settings: {new_quizzes: {type: 'graded_survey'}},
      })
      expect(assignment.newQuizzesType()).toBe('graded_survey')
    })

    it('sets the type in settings when called with a value', () => {
      const assignment = new Assignment()
      assignment.newQuizzesType('ungraded_survey')
      expect(assignment.get('settings')).toEqual({
        new_quizzes: {type: 'ungraded_survey'},
      })
    })

    it('preserves existing settings when setting type', () => {
      const assignment = new Assignment({
        settings: {
          some_other_setting: 'value',
        },
      })
      assignment.newQuizzesType('graded_survey')
      expect(assignment.get('settings')).toEqual({
        some_other_setting: 'value',
        new_quizzes: {type: 'graded_survey'},
      })
    })

    it('preserves existing new_quizzes settings when setting type', () => {
      const assignment = new Assignment({
        settings: {
          new_quizzes: {
            other_field: 'other_value',
          },
        },
      })
      assignment.newQuizzesType('ungraded_survey')
      expect(assignment.get('settings')).toEqual({
        new_quizzes: {
          other_field: 'other_value',
          type: 'ungraded_survey',
        },
      })
    })

    it('overwrites existing type when setting a new type', () => {
      const assignment = new Assignment({
        settings: {
          new_quizzes: {
            type: 'graded_quiz',
            other_field: 'other_value',
          },
        },
      })
      assignment.newQuizzesType('graded_survey')
      expect(assignment.get('settings')).toEqual({
        new_quizzes: {
          type: 'graded_survey',
          other_field: 'other_value',
        },
      })
    })
  })
})
