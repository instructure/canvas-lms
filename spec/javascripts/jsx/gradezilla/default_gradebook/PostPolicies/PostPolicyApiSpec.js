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

import MockCanvasClient from '../../../../support/MockCanvasClient'
import * as PostPolicyApi from 'jsx/gradezilla/default_gradebook/PostPolicies/PostPolicyApi'

QUnit.module('PostPolicyApi', () => {
  QUnit.module('.setCoursePostPolicy()', hooks => {
    const VALID_COURSE_ID = 10
    const ERROR_COURSE_ID = 987
    const BAD_RESPONSE_COURSE_ID = -11

    hooks.beforeEach(() => {
      MockCanvasClient.install([
        {
          request: {
            query: PostPolicyApi.SET_COURSE_POST_POLICY_MUTATION,
            variables: {courseId: VALID_COURSE_ID, postManually: true}
          },

          result: {
            data: {
              setCoursePostPolicy: {
                __typename: 'SetCoursePostPolicy',
                errors: [],
                postPolicy: {
                  postManually: true,
                  __typename: 'PostPolicy'
                }
              }
            }
          }
        },

        {
          request: {
            query: PostPolicyApi.SET_COURSE_POST_POLICY_MUTATION,
            variables: {courseId: ERROR_COURSE_ID, postManually: true}
          },

          result: {
            data: {
              setCoursePostPolicy: {
                __typename: 'SetCoursePostPolicy',
                errors: [
                  {__typename: 'Error', attribute: 'badness', message: 'oh no'},
                  {__typename: 'Error', attribute: 'more badness', message: 'oh nooooo'}
                ],
                postPolicy: null
              }
            }
          }
        },

        {
          request: {
            query: PostPolicyApi.SET_COURSE_POST_POLICY_MUTATION,
            variables: {courseId: BAD_RESPONSE_COURSE_ID, postManually: true}
          },

          result: {
            data: {}
          }
        }
      ])
    })

    hooks.afterEach(() => {
      MockCanvasClient.uninstall()
    })

    test('returns the postManually value if the response includes a postPolicy object', async () => {
      const result = await PostPolicyApi.setCoursePostPolicy({
        courseId: VALID_COURSE_ID,
        postManually: true
      })
      deepEqual(result, {postManually: true})
    })

    test('returns the first error if the response includes errors', async () => {
      const result = await PostPolicyApi.setCoursePostPolicy({
        courseId: ERROR_COURSE_ID,
        postManually: true
      })
      deepEqual(result, {error: 'oh no'})
    })

    test('returns an error if the response provides neither a postPolicy object nor an error', async () => {
      const result = await PostPolicyApi.setCoursePostPolicy({
        courseId: BAD_RESPONSE_COURSE_ID,
        postManually: true
      })
      deepEqual(result, {error: 'no postPolicy or error provided in response'})
    })
  })
})
