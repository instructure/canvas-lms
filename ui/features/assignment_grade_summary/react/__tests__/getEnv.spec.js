/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import getEnv from '../getEnv'

describe('GradeSummary getEnv()', () => {
  beforeEach(() => {
    fakeENV.setup({
      ASSIGNMENT: {
        course_id: '1201',
        id: '2301',
        muted: true,
        grades_published: false,
        title: 'Example Assignment',
      },
      CURRENT_USER: {
        can_view_grader_identities: true,
        can_view_student_identities: false,
        grader_id: 'admin',
        id: '1100',
      },
      FINAL_GRADER: {
        grader_id: 'teach',
        id: '1105',
      },
      GRADERS: [
        {grader_name: 'Charlie Xi', id: '4502', user_id: '1103', grader_selectable: true},
        {grader_name: 'Adam Jones', id: '4503', user_id: '1101', grader_selectable: true},
        {grader_name: 'Betty Ford', id: '4501', user_id: '1102', grader_selectable: false},
      ],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('.assignment', () => {
    test('camel-cases .courseId', () => {
      expect(getEnv().assignment.courseId).toBe('1201')
    })

    test('includes .id', () => {
      expect(getEnv().assignment.id).toBe('2301')
    })

    test('includes .muted', () => {
      expect(getEnv().assignment.muted).toBe(true)
    })

    test('camel-cases .gradesPublished', () => {
      expect(getEnv().assignment.gradesPublished).toBe(false)
    })

    test('includes .title', () => {
      expect(getEnv().assignment.title).toBe('Example Assignment')
    })
  })

  describe('.currentUser', () => {
    test('camel-cases .canViewGraderIdentities', () => {
      expect(getEnv().currentUser.canViewGraderIdentities).toBe(true)
    })

    test('camel-cases .canViewStudentIdentities', () => {
      expect(getEnv().currentUser.canViewStudentIdentities).toBe(false)
    })

    test('camel-cases .graderId', () => {
      expect(getEnv().currentUser.graderId).toBe('admin')
    })

    test('defaults .graderId to "FINAL_GRADER" when the user is the final grader', () => {
      ENV.CURRENT_USER.id = '1105'
      delete ENV.FINAL_GRADER.grader_id
      delete ENV.CURRENT_USER.grader_id
      expect(getEnv().currentUser.graderId).toBe('FINAL_GRADER')
    })

    test('defaults .graderId to "CURRENT_USER" when the user is not the final grader', () => {
      delete ENV.FINAL_GRADER.grader_id
      delete ENV.CURRENT_USER.grader_id
      ENV.CURRENT_USER.id = '1100'
      expect(getEnv().currentUser.graderId).toBe('CURRENT_USER')
    })

    test('includes .id', () => {
      expect(getEnv().currentUser.id).toBe('1100')
    })
  })

  describe('.finalGrader', () => {
    test('camel-cases .graderId', () => {
      expect(getEnv().finalGrader.graderId).toBe('teach')
    })

    test('defaults .graderId to "FINAL_GRADER"', () => {
      delete ENV.FINAL_GRADER.grader_id
      expect(getEnv().finalGrader.graderId).toBe('FINAL_GRADER')
    })

    test('includes .id', () => {
      expect(getEnv().finalGrader.id).toBe('1105')
    })

    test('is null when there is no final grader', () => {
      delete ENV.FINAL_GRADER
      expect(getEnv().finalGrader).toBeNull()
    })
  })

  describe('.graders', () => {
    describe('when graders are not anonymous', () => {
      test('includes all GRADERS', () => {
        expect(getEnv().graders.length).toBe(3)
      })

      test('includes .id', () => {
        const ids = getEnv()
          .graders.map(grader => grader.id)
          .sort()
        expect(ids).toEqual(['4501', '4502', '4503'])
      })

      test('camel-cases .graderId on graders', () => {
        const graderIds = getEnv()
          .graders.map(grader => grader.graderId)
          .sort()
        expect(graderIds).toEqual(['1101', '1102', '1103'])
      })

      test('sorts graders by .graderId', () => {
        const graderIds = getEnv().graders.map(grader => grader.graderId)
        expect(graderIds).toEqual(['1101', '1102', '1103'])
      })

      test('camel-cases .graderName', () => {
        const graderNames = getEnv().graders.map(grader => grader.graderName)
        expect(graderNames).toEqual(['Adam Jones', 'Betty Ford', 'Charlie Xi'])
      })

      test('includes .graderSelectable', () => {
        const graders = getEnv().graders

        const deletedGrader = graders.find(grader => grader.graderName === 'Betty Ford')
        expect(deletedGrader.graderSelectable).toBe(false)

        const activeGrader = graders.find(grader => grader.graderName === 'Adam Jones')
        expect(activeGrader.graderSelectable).toBe(true)
      })
    })

    describe('when graders are anonymous', () => {
      beforeEach(() => {
        ENV.GRADERS = [
          {anonymous_id: 'h2asd', id: '4502'},
          {anonymous_id: 'abcde', id: '4503'},
          {anonymous_id: 'b01ng', id: '4501'},
        ]
      })

      test('includes all GRADERS', () => {
        expect(getEnv().graders.length).toBe(3)
      })

      test('includes .id', () => {
        const ids = getEnv()
          .graders.map(grader => grader.id)
          .sort()
        expect(ids).toEqual(['4501', '4502', '4503'])
      })

      test('uses .anonymous_id as .graderId', () => {
        const graderIds = getEnv()
          .graders.map(grader => grader.graderId)
          .sort()
        expect(graderIds).toEqual(['abcde', 'b01ng', 'h2asd'])
      })

      test('sorts graders by the anonymous .graderId', () => {
        const graderIds = getEnv().graders.map(grader => grader.graderId)
        expect(graderIds).toEqual(['abcde', 'b01ng', 'h2asd'])
      })

      test('assigns enumerated names', () => {
        const graderNames = getEnv().graders.map(grader => grader.graderName)
        expect(graderNames).toEqual(['Grader 1', 'Grader 2', 'Grader 3'])
      })
    })
  })
})
