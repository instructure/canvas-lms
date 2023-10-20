/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AssignmentSingleAvailabilityWindow} from '../AssignmentSingleAvailabilityWindow'
import {Assignment} from '../../../../graphql/Assignment'

import {responsiveQuerySizes} from '../../../utils/index'

import React from 'react'
import {render} from '@testing-library/react'

jest.mock('../../../utils')

const mockOverrides = [
  {
    id: 'QXNzaWdebTVubC0x',
    _id: '1',
    dueAt: '2021-03-30T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-24T00:00:00-06:00',
    title: 'assignment override 1',
  },
  {
    id: 'ZXMzaWdebTubeC0x',
    _id: '2',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 2',
  },
  {
    id: 'BXMzaWdebTVubC0x',
    _id: '3',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-09-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 3',
  },
]

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = (props = {}) => {
  return render(
    <AssignmentSingleAvailabilityWindow
      assignmentOverrides={mockOverrides}
      assignment={Assignment.mock()}
      isAdmin={true}
      singleOverrideWithNoDefault={false}
      onSetDueDateTrayOpen={jest.fn()}
      {...props}
    />
  )
}

describe('AssignmentSingleAvailabilityWindow', () => {
  describe('desktop', () => {
    it('should render', () => {
      const container = setup({assignmentOverrides: []})
      expect(container.getByText('Everyone')).toBeInTheDocument()
      expect(container.getByText('Due Mar 31, 2021 5:59am')).toBeInTheDocument()
      expect(
        container.getByText('Available from Mar 24, 2021 until Apr 4, 2021')
      ).toBeInTheDocument()
    })

    it('should show participant list when sinlge override is defined with student list', () => {
      const container = setup({
        assignmentOverrides: [
          {
            id: '29',
            _id: '29',
            dueAt: '2021-09-08T23:59:00-06:00',
            lockAt: '2021-09-15T23:59:59-06:00',
            unlockAt: '2021-09-01T00:00:00-06:00',
            title: '1 student',
            set: {
              students: [{shortName: 'Tom Jones', __typename: 'User'}],
              __typename: 'AdhocStudents',
            },
            __typename: 'AssignmentOverride',
          },
        ],
        singleOverrideWithNoDefault: true,
      })

      expect(container.getByText('Tom Jones')).toBeInTheDocument()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '767px'},
      }))
    })

    it('should render', () => {
      const container = setup({assignmentOverrides: []})
      expect(container.getByText('Due Mar 31, 2021')).toBeInTheDocument()
    })
  })
})
