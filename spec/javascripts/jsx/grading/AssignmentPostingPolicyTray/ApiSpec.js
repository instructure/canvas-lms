/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import MockCanvasClient from '../../../support/MockCanvasClient'
import * as Api from 'ui/features/gradebook/react/AssignmentPostingPolicyTray/Api'

QUnit.module('AssignmentPostingPolicyTray Api', () => {
  QUnit.module('.setAssignmentPostPolicy()', hooks => {
    const ASSIGNMENT_ID = '23'
    const BAD_ASSIGNMENT_ID = '24'
    const BAD_RESPONSE_ASSIGNMENT_ID = '-29'

    hooks.beforeEach(() => {
      MockCanvasClient.install([
        {
          request: {
            query: Api.SET_ASSIGNMENT_POST_POLICY_MUTATION,
            variables: {assignmentId: ASSIGNMENT_ID, postManually: true},
          },
          result: {
            data: {
              setAssignmentPostPolicy: {
                __typename: 'SetAssignmentPostPolicy',
                errors: [],
                postPolicy: {
                  postManually: true,
                  __typename: 'PostPolicy',
                },
              },
            },
          },
        },
        {
          request: {
            query: Api.SET_ASSIGNMENT_POST_POLICY_MUTATION,
            variables: {assignmentId: BAD_ASSIGNMENT_ID, postManually: true},
          },
          result: {
            data: {
              setAssignmentPostPolicy: {
                __typename: 'SetAssignmentPostPolicy',
                errors: [
                  {__typename: 'Error', attribute: 'severity', message: 'complete disaster'},
                  {__typename: 'Error', attribute: 'severity', message: 'another disaster'},
                ],
                postPolicy: null,
              },
            },
          },
        },
        {
          request: {
            query: Api.SET_ASSIGNMENT_POST_POLICY_MUTATION,
            variables: {assignmentId: BAD_RESPONSE_ASSIGNMENT_ID, postManually: true},
          },
          result: {
            data: {},
          },
        },
      ])
    })

    hooks.afterEach(() => {
      MockCanvasClient.uninstall()
    })

    test('returns the postManually value if the response includes a postPolicy object', async () => {
      const result = await Api.setAssignmentPostPolicy({
        assignmentId: ASSIGNMENT_ID,
        postManually: true,
      })
      deepEqual(result, {postManually: true})
    })

    test('throws an error containing the first error message if the response includes errors', async () => {
      Api.setAssignmentPostPolicy({
        assignmentId: BAD_ASSIGNMENT_ID,
        postManually: true,
      }).catch(error => {
        strictEqual(error.message, 'complete disaster')
      })
    })

    test('throws an error if the response provides neither a postPolicy object nor an error', async () => {
      Api.setAssignmentPostPolicy({
        assignmentId: BAD_RESPONSE_ASSIGNMENT_ID,
        postManually: true,
      }).catch(error => {
        strictEqual(error.message, 'no postPolicy or error provided in response')
      })
    })
  })
})
