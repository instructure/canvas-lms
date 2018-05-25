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

import fakeENV from 'helpers/fakeENV'

import getEnv from 'jsx/assignments/GradeSummary/getEnv'

QUnit.module('GradeSummary getEnv()', suiteHooks => {
  suiteHooks.beforeEach(() => {
    fakeENV.setup({
      ASSIGNMENT: {
        course_id: '1201',
        id: '2301',
        muted: true,
        grades_published: false,
        title: 'Example Assignment'
      },
      GRADERS: [
        {grader_name: 'Charlie Xi', id: '4502', user_id: '1103'},
        {grader_name: 'Adam Jones', id: '4503', user_id: '1101'},
        {grader_name: 'Betty Ford', id: '4501', user_id: '1102'}
      ]
    })
  })

  suiteHooks.afterEach(() => {
    fakeENV.teardown()
  })

  QUnit.module('.assignment', () => {
    test('camel-cases .courseId', () => {
      strictEqual(getEnv().assignment.courseId, '1201')
    })

    test('includes .id', () => {
      strictEqual(getEnv().assignment.id, '2301')
    })

    test('includes .muted', () => {
      strictEqual(getEnv().assignment.muted, true)
    })

    test('camel-cases .gradesPublished', () => {
      strictEqual(getEnv().assignment.gradesPublished, false)
    })

    test('includes .title', () => {
      strictEqual(getEnv().assignment.title, 'Example Assignment')
    })
  })

  QUnit.module('.graders', () => {
    QUnit.module('when graders are not anonymous', () => {
      test('includes all GRADERS', () => {
        strictEqual(getEnv().graders.length, 3)
      })

      test('includes .id', () => {
        const ids = getEnv()
          .graders.map(grader => grader.id)
          .sort()
        deepEqual(ids, ['4501', '4502', '4503'])
      })

      test('camel-cases .graderId on graders', () => {
        const graderIds = getEnv()
          .graders.map(grader => grader.graderId)
          .sort()
        deepEqual(graderIds, ['1101', '1102', '1103'])
      })

      test('sorts graders by .graderId', () => {
        const graderIds = getEnv().graders.map(grader => grader.graderId)
        deepEqual(graderIds, ['1101', '1102', '1103'])
      })

      test('camel-cases .graderName', () => {
        const graderNames = getEnv().graders.map(grader => grader.graderName)
        deepEqual(graderNames, ['Adam Jones', 'Betty Ford', 'Charlie Xi'])
      })
    })

    QUnit.module('when graders are anonymous', hooks => {
      hooks.beforeEach(() => {
        ENV.GRADERS = [
          {anonymous_id: 'h2asd', id: '4502'},
          {anonymous_id: 'abcde', id: '4503'},
          {anonymous_id: 'b01ng', id: '4501'}
        ]
      })

      test('includes all GRADERS', () => {
        strictEqual(getEnv().graders.length, 3)
      })

      test('includes .id', () => {
        const ids = getEnv()
          .graders.map(grader => grader.id)
          .sort()
        deepEqual(ids, ['4501', '4502', '4503'])
      })

      test('uses .anonymous_id as .graderId', () => {
        const graderIds = getEnv()
          .graders.map(grader => grader.graderId)
          .sort()
        deepEqual(graderIds, ['abcde', 'b01ng', 'h2asd'])
      })

      test('sorts graders by the anonymous .graderId', () => {
        const graderIds = getEnv().graders.map(grader => grader.graderId)
        deepEqual(graderIds, ['abcde', 'b01ng', 'h2asd'])
      })

      test('assigns enumerated names', () => {
        const graderNames = getEnv().graders.map(grader => grader.graderName)
        deepEqual(graderNames, ['Grader 1', 'Grader 2', 'Grader 3'])
      })
    })
  })
})
