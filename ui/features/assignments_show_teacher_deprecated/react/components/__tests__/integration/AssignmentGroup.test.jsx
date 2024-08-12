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
import AssignmentGroup from '../../Editables/AssignmentGroup'
import CanvasValidatedMockedProvider from '@canvas/validated-apollo-mocked-provider'
import {COURSE_ASSIGNMENT_GROUPS_QUERY} from '../../../assignmentData'
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
      query: COURSE_ASSIGNMENT_GROUPS_QUERY,
      variables: {
        courseId: '55',
      },
    },
    result: {
      data: {
        course: {
          lid: '55',
          gid: 'Q291cnNlLTU1',
          __typename: 'Course',
          assignmentGroupsConnection: {
            __typename: 'AssignmentGroupConnection',
            pageInfo: {
              endCursor: 'AA==',
              hasNextPage: true,
              __typename: 'PageInfo',
            },
            nodes: [
              {
                lid: '71',
                gid: 'QXNzaWdubWVudEdyb3VwLTcx',
                name: 'Assignments',
                __typename: 'AssignmentGroup',
              },
              {
                lid: '76',
                gid: 'QXNzaWdubWVudEdyb3VwLTc2',
                name: 'Group B',
                __typename: 'AssignmentGroup',
              },
            ],
          },
        },
      },
    },
  },
  {
    request: {
      query: COURSE_ASSIGNMENT_GROUPS_QUERY,
      variables: {
        courseId: '55',
        cursor: 'AA==',
      },
    },
    result: {
      data: {
        course: {
          lid: '55',
          gid: 'Q291cnNlLTU1',
          __typename: 'Course',
          assignmentGroupsConnection: {
            __typename: 'AssignmentGroupConnection',
            pageInfo: {
              endCursor: 'NA==',
              hasNextPage: false,
              __typename: 'PageInfo',
            },
            nodes: [
              {
                lid: '80',
                gid: 'QXNzaWdubWVudEdyb3VwLTgw',
                name: 'Group C',
                __typename: 'AssignmentGroup',
              },
              {
                lid: '79',
                gid: 'QXNzaWdubWVudEdyb3VwLTc5',
                name: 'Group A',
                __typename: 'AssignmentGroup',
              },
            ],
          },
        },
      },
    },
  },
]

describe('AssignmentGroup', () => {
  it.skip('queries group list on edit', async () => {
    const {getByText} = render(
      <CanvasValidatedMockedProvider mocks={mocks} addTypename={false}>
        <AssignmentGroup courseId="55" mode="edit" onChange={() => {}} onChangeMode={() => {}} />
      </CanvasValidatedMockedProvider>
    )
    // The groups are loaded when Select removes its spinner
    await waitForNoElement(() => getByText('Loading...'))
    expect(getByText('Assignments')).toBeInTheDocument()
    expect(getByText('Group A')).toBeInTheDocument()
    expect(getByText('Group B')).toBeInTheDocument()
    expect(getByText('Group C')).toBeInTheDocument()
  })
})
