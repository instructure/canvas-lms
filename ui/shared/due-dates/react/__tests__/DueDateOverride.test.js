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

import $ from 'jquery'
import 'jquery-migrate'
import DateValidator from '@canvas/grading/DateValidator'
import DueDateOverrideView from '@canvas/due-dates'
import StudentGroupStore from '../StudentGroupStore'
import '@canvas/jquery/jquery.instructure_forms'

describe('DueDateOverride', () => {
  let fixtures

  beforeEach(() => {
    fixtures = document.getElementById('fixtures')
    if (!fixtures) {
      fixtures = document.createElement('div')
      fixtures.id = 'fixtures'
      document.body.appendChild(fixtures)
    }

    // Mock jQuery errorBox with chaining
    const $mockElement = {
      css: jest.fn().mockReturnThis(),
      attr: jest.fn().mockReturnThis(),
    }
    $.fn.errorBox = jest.fn().mockReturnValue($mockElement)
    $.fn.errorBox.errorBoxes = []
    $.moveErrorBoxes = jest.fn()
  })

  afterEach(() => {
    fixtures.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('#validateTokenInput', () => {
    beforeEach(() => {
      fixtures.innerHTML = `
        <div data-row-key="01" class="Container__DueDateRow-item">
          <div data-row-identifier="tokenInputFor01">
            <input />
          </div>
        </div>
      `
    })

    it('rowKey can be prefixed with a zero', () => {
      const view = new DueDateOverrideView()
      const errs = view.validateTokenInput({}, {})
      view.showError(errs.blankOverrides.element, errs.blankOverrides.message)
      expect($.fn.errorBox).toHaveBeenCalled()
    })
  })

  describe('#validateGroupOverrides', () => {
    beforeEach(() => {
      fixtures.innerHTML = `
        <div data-row-key="01" class="Container__DueDateRow-item">
          <div data-row-identifier="tokenInputFor01">
            <input />
          </div>
        </div>
      `
    })

    it('rowKey can be prefixed with a zero', () => {
      const data = {assignment_overrides: [{group_id: '42', rowKey: '01'}]}

      jest.spyOn(StudentGroupStore, 'fetchComplete').mockReturnValue(true)
      jest.spyOn(StudentGroupStore, 'groupsFilteredForSelectedSet').mockReturnValue([])
      const view = new DueDateOverrideView()
      const errs = view.validateGroupOverrides(data, {})
      view.showError(errs.invalidGroupOverride.element, errs.invalidGroupOverride.message)
      expect($.fn.errorBox).toHaveBeenCalled()
    })

    it('Does not date restrict individual student overrides', () => {
      const data = {assignment_overrides: [{student_ids: [20], rowKey: '16309'}]}

      jest.spyOn(StudentGroupStore, 'fetchComplete').mockReturnValue(true)
      jest.spyOn(StudentGroupStore, 'groupsFilteredForSelectedSet').mockReturnValue([])
      const view = new DueDateOverrideView()
      const errs = view.validateGroupOverrides(data, {})
      expect(errs.invalidGroupOverride).toBeUndefined()
    })
  })

  describe('#validateDatetimes', () => {
    it('skips overrides whose row key has already been validated', () => {
      const overrides = [
        {rowKey: '1', student_ids: [1]},
        {rowKey: '1', student_ids: [1]},
      ]
      const data = {assignment_overrides: overrides}

      const validateSpy = jest.spyOn(DateValidator.prototype, 'validateDatetimes')
      const view = new DueDateOverrideView()
      jest.spyOn(view, 'postToSIS').mockReturnValue(false)

      view.validateDatetimes(data, {})

      expect(validateSpy).toHaveBeenCalledTimes(1)
    })

    describe('when a valid date range is specified', () => {
      const oldEnv = window.ENV

      beforeEach(() => {
        window.ENV = {
          VALID_DATE_RANGE: {
            start_at: {
              date: new Date('Nov 10, 2018').toISOString(),
              date_context: 'course',
            },
            end_at: {
              date: new Date('Nov 20, 2018').toISOString(),
              date_context: 'course',
            },
          },
        }
      })

      afterEach(() => {
        window.ENV = oldEnv
      })

      it('allows dates for individual students to fall outside of the specified date range', () => {
        const dueDate = new Date('Nov 30, 2018').toISOString()
        const overrides = [{rowKey: '1', student_ids: [1], due_at: dueDate}]
        const data = {assignment_overrides: overrides}

        const view = new DueDateOverrideView()
        jest.spyOn(view, 'postToSIS').mockReturnValue(false)

        const errors = view.validateDatetimes(data, {})
        expect(Object.keys(errors)).toHaveLength(0)
      })

      it('requires non-individual-student overrides to be within specified date range', () => {
        const dueDate = new Date('Nov 30, 2018').toISOString()
        const overrides = [{rowKey: '1', course_section_id: '1', due_at: dueDate}]
        const data = {assignment_overrides: overrides}

        const view = new DueDateOverrideView()
        jest.spyOn(view, 'postToSIS').mockReturnValue(false)

        const errors = view.validateDatetimes(data, {})
        expect(errors.due_at.message).toBe('Due date cannot be after course end')
      })

      it('does not validate dates for an assignment in a paced course', () => {
        const view = new DueDateOverrideView({inPacedCourse: true, isModuleItem: true})
        const dueDate = new Date('Nov 30, 2018').toISOString()
        const overrides = [{rowKey: '1', student_ids: [1], due_at: dueDate}]
        const data = {assignment_overrides: overrides}

        const errors = view.validateBeforeSave(data, {})
        expect(Object.keys(errors)).toHaveLength(0)
      })
    })

    describe('with course pacing', () => {
      it('shows notice when in a paced course', () => {
        const view = new DueDateOverrideView({inPacedCourse: true, isModuleItem: true})
        view.render()
        const el = view.$el
        expect(el[0].querySelector('[data-testid="CoursePacingNotice"]')).toBeTruthy()
      })
    })
  })
})
