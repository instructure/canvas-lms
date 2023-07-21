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

import {TrayDisplayer} from '../TrayDisplayer'
import {DiscussionAvailabilityTray} from '../../DiscussionAvailabilityTray/DiscussionAvailabilityTray'
import {DueDateTray} from '../../DueDateTray/DueDateTray'
import {responsiveQuerySizes} from '../../../utils/index'

import React from 'react'
import {render} from '@testing-library/react'

jest.mock('../../../utils')

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

const mockLockAt = '2022-01-19T23:59:59-07:00'
const mockDelayedPost = '2022-01-12T00:00:00-07:00'
const mockAvailabities = [
  {
    id: 'U2VjdGlvbi00',
    _id: '1',
    userCount: 5231,
    name: 'section 1',
  },
  {
    id: 'U2VjdGlvbi01',
    _id: '2',
    userCount: 99,
    name: 'section 2',
  },
]

const setup = (props = {}) => {
  return render(
    <TrayDisplayer
      setTrayOpen={jest.fn()}
      trayTitle="Due Dates"
      trayComponent={<DueDateTray assignmentOverrides={mockOverrides} isAdmin={true} />}
      isTrayOpen={true}
      {...props}
    />
  )
}

describe('TrayDisplayer', () => {
  describe('dueDateTray', () => {
    it('should render', () => {
      const container = setup()
      expect(container.getAllByText('Due Dates')[0]).toBeInTheDocument()
      expect(container.getAllByText('Due Dates')[1]).toBeInTheDocument()
    })

    it('renders correct data in the dueDateTray', () => {
      const container = setup()
      expect(container.getAllByTestId('assignment-override-row').length).toBe(mockOverrides.length)
      expect(container.getByText('assignment override 1')).toBeInTheDocument()
      expect(container.getByText('assignment override 2')).toBeInTheDocument()
      expect(container.getByText('assignment override 2')).toBeInTheDocument()
      expect(container.getByText('Sep 4, 2021 5:59am')).toBeTruthy()
    })
  })

  describe('DiscussionAvailabilityTray', () => {
    it('should render', () => {
      const container = setup({
        trayTitle: 'Availability',
        trayComponent: (
          <DiscussionAvailabilityTray
            lockAt={mockLockAt}
            delayedPostAt={mockDelayedPost}
            availabilities={mockAvailabities}
          />
        ),
      })
      expect(container.getAllByText('Availability')[0]).toBeInTheDocument()
      expect(container.getAllByText('Availability')[1]).toBeInTheDocument()
      expect(container.getByTestId('availability-table')).toBeInTheDocument()
    })
    it('renders correct data in the DiscussionAvailabilityTray', () => {
      const container = setup({
        trayTitle: 'Availability',
        trayComponent: (
          <DiscussionAvailabilityTray
            lockAt={mockLockAt}
            delayedPostAt={mockDelayedPost}
            availabilities={mockAvailabities}
          />
        ),
      })
      expect(container.getAllByTestId('availabilities-row').length).toBe(mockAvailabities.length)
      expect(container.getByText('section 1')).toBeInTheDocument()
      expect(container.getByText('section 2')).toBeInTheDocument()
      expect(container.getByText('99')).toBeInTheDocument()
      expect(container.getByText('5231')).toBeInTheDocument()
    })
  })
})
