/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook Assignment Actions', () => {
  let gradebook
  let assignments

  beforeEach(() => {
    gradebook = createGradebook({
      download_assignment_submissions_url: 'http://example.com/submissions',
    })

    assignments = [
      {
        id: '2301',
        submission_types: ['online_text_entry'],
      },
      {
        id: '2302',
        submission_types: ['online_text_entry'],
      },
    ]

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
      {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
    ])
  })

  describe('#getDownloadSubmissionsAction', () => {
    test('includes the "hidden" property', () => {
      const action = gradebook.getDownloadSubmissionsAction('2301')
      expect(typeof action.hidden).toBe('boolean')
    })

    test('includes the "onSelect" callback', () => {
      const action = gradebook.getDownloadSubmissionsAction('2301')
      expect(typeof action.onSelect).toBe('function')
    })
  })

  describe('#getReuploadSubmissionsAction', () => {
    test('includes the "hidden" property', () => {
      const action = gradebook.getReuploadSubmissionsAction('2301')
      expect(typeof action.hidden).toBe('boolean')
    })

    test('includes the "onSelect" callback', () => {
      const action = gradebook.getReuploadSubmissionsAction('2301')
      expect(typeof action.onSelect).toBe('function')
    })
  })

  describe('#getSetDefaultGradeAction', () => {
    test('includes the "disabled" property', () => {
      const action = gradebook.getSetDefaultGradeAction('2301')
      expect(typeof action.disabled).toBe('boolean')
    })

    test('includes the "onSelect" callback', () => {
      const action = gradebook.getSetDefaultGradeAction('2301')
      expect(typeof action.onSelect).toBe('function')
    })
  })

  describe('#getCurveGradesAction', () => {
    test('includes the "isDisabled" property', () => {
      const action = gradebook.getCurveGradesAction('2301')
      expect(typeof action.isDisabled).toBe('boolean')
    })

    test('includes the "onSelect" callback', () => {
      const action = gradebook.getCurveGradesAction('2301')
      expect(typeof action.onSelect).toBe('function')
    })
  })
})
