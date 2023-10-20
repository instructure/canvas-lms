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

import {AssignmentMultipleAvailabilityWindows} from '../AssignmentMultipleAvailabilityWindows'

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

const setup = props => {
  return render(
    <AssignmentMultipleAvailabilityWindows
      assignmentOverrides={mockOverrides}
      onSetDueDateTrayOpen={jest.fn()}
      {...props}
    />
  )
}

describe('AssignmentAvailabilityContainer', () => {
  describe('desktop', () => {
    it('should render', () => {
      const container = setup()
      expect(container.getByText('Show Due Dates (3)')).toBeInTheDocument()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '767px'},
      }))
    })

    it('should render', () => {
      const container = setup()
      expect(container.getByText('Due Dates (3)')).toBeInTheDocument()
    })
  })
})
