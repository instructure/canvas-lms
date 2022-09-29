/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MockCanvasClient from './support/MockCanvasClient'
import {createClient, gql} from 'jsx/canvas-apollo'

QUnit.module('Apollo without React demo spec', hooks => {
  const COURSE_INFO_QUERY = gql`
    query courseInfo($id: ID!) {
      course(id: $id) {
        id
        name
      }
    }
  `

  const getCourseInfo = courseId =>
    createClient()
      .query({
        query: COURSE_INFO_QUERY,
        variables: {id: courseId},
      })
      .then(({data}) => {
        const {id, name} = data.course
        return `${id} - ${name}`
      })
      .catch(_err => 'Something went wrong')

  hooks.beforeEach(() => {
    MockCanvasClient.install([
      {
        request: {
          query: COURSE_INFO_QUERY,
          variables: {id: 'GOOD'},
        },
        result: {
          data: {
            course: {
              id: 'asdf',
              name: 'First Course',
              __typename: 'Course',
            },
          },
        },
      },
      {
        request: {
          query: COURSE_INFO_QUERY,
          variables: {id: 'ERR1'},
        },
        result: {
          errors: [{message: 'uh oh graphql response error'}],
        },
      },
      {
        request: {
          query: COURSE_INFO_QUERY,
          variables: {id: 'ERR2'},
        },
        error: new Error('uh oh transport or other kind of error'),
      },
    ])
  })

  hooks.afterEach(() => {
    MockCanvasClient.uninstall()
  })

  test('works', async () => {
    const response = await getCourseInfo('GOOD')
    equal(response, 'asdf - First Course')
  })

  test('works with query response errors', async () => {
    const response = await getCourseInfo('ERR1')
    equal(response, 'Something went wrong')
  })

  test('works when something goes wrong', async () => {
    const response = await getCourseInfo('ERR2')
    equal(response, 'Something went wrong')
  })
})
