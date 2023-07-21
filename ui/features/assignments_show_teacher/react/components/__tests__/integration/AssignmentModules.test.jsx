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

import React from 'react'
import {render} from '@testing-library/react'
import AssignmentModules from '../../Editables/AssignmentModules'
import CanvasValidatedMockedProvider from '@canvas/validated-apollo-mocked-provider'
import {COURSE_MODULES_QUERY} from '../../../assignmentData'
import {waitForNoElement} from '../../../test-utils'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

const mocks = [
  {
    request: {
      query: COURSE_MODULES_QUERY,
      variables: {
        courseId: '55',
      },
    },
    result: {
      data: {
        course: {
          lid: '55',
          gid: 'Q291cnNlLTU1',
          modulesConnection: {
            pageInfo: {
              endCursor: 'Ng==',
              hasNextPage: true,
              __typename: 'PageInfo',
            },
            __typename: 'ModuleConnection',
            nodes: [
              {
                lid: '79',
                gid: 'TW9kdWxlLTc5',
                name: 'Module X',
                position: 1,
                __typename: 'Module',
              },
              {
                lid: '80',
                gid: 'TW9kdWxlLTgw',
                name: 'Module Y',
                position: 2,
                __typename: 'Module',
              },
            ],
          },
          __typename: 'Course',
        },
      },
    },
  },
  {
    request: {
      query: COURSE_MODULES_QUERY,
      variables: {
        courseId: '55',
        cursor: 'Ng==',
      },
    },
    result: {
      data: {
        course: {
          lid: '55',
          gid: 'Q291cnNlLTU1',
          modulesConnection: {
            pageInfo: {
              endCursor: 'XX==',
              hasNextPage: false,
              __typename: 'PageInfo',
            },
            __typename: 'ModuleConnection',
            nodes: [
              {
                lid: '81',
                gid: 'TW9kdWxlLTgx',
                name: 'Module Z',
                position: 3,
                __typename: 'Module',
              },
            ],
          },
          __typename: 'Course',
        },
      },
    },
  },
]

describe('AssignmentModules', () => {
  it.skip('queries group list on edit', async () => {
    const {getByText} = render(
      <CanvasValidatedMockedProvider mocks={mocks} addTypename={false}>
        <AssignmentModules
          courseId="55"
          mode="edit"
          onChange={() => {}}
          onChangeMode={() => {}}
          readOnly={false}
        />
      </CanvasValidatedMockedProvider>
    )
    // The modules are loded when Select removes its spinner
    await waitForNoElement(() => getByText('Loading...'))
    expect(getByText('Module X')).toBeInTheDocument()
    expect(getByText('Module Y')).toBeInTheDocument()
    expect(getByText('Module Z')).toBeInTheDocument()
  })
})
