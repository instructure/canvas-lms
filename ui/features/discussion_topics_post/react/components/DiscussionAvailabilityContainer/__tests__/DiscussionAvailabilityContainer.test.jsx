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

import {responsiveQuerySizes} from '../../../utils/index'

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import {DiscussionAvailabilityContainer} from '../DiscussionAvailabilityContainer'

jest.mock('../../../utils')

const mockSections = [
  {
    id: 'U2VjdGlvbi00',
    _id: '1',
    userCount: 99,
    name: 'section 2',
  },
  {
    id: 'U2VjdGlvbi01',
    _id: '1',
    userCount: 990,
    name: 'section 25',
  },
]
const mockLockAt = '2022-01-19T23:59:59-07:00'
const mockDelayedPost = '2022-01-12T00:00:00-07:00'

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
    <DiscussionAvailabilityContainer
      courseSections={mockSections}
      totalUserCount={5}
      anonymousState={null}
      delayedPostAt={mockDelayedPost}
      lockAt={mockLockAt}
      {...props}
    />
  )
}

describe('DiscussionAvailabilityContainer', () => {
  describe('desktop', () => {
    it('displays View Availability', () => {
      const {queryByText} = setup()
      expect(queryByText('View Availability')).toBeInTheDocument()
    })
    it('displays anonymous discussion when anonymous', () => {
      const {queryByText} = setup({anonymousState: 'full_anonymity'})
      expect(queryByText('Anonymous Discussion')).toBeInTheDocument()
    })

    it('displays partially anonymous discussion when partially anonymous', () => {
      const {queryByText} = setup({anonymousState: 'partial_anonymity'})
      expect(queryByText('Partially Anonymous Discussion')).toBeInTheDocument()
    })

    it('clicking view availability opens the tray', () => {
      const container = setup()
      const viewAvailabilityButton = container.queryByText('View Availability')
      fireEvent.click(viewAvailabilityButton)
      expect(container.getByText('99')).toBeInTheDocument()
      expect(container.getByText('section 2')).toBeInTheDocument()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '767px'},
      }))
    })

    it('displays View Availability', () => {
      const {queryByText} = setup()
      expect(queryByText('View Availability')).toBeInTheDocument()
    })
    it('displays anonymous discussion when anonymous', () => {
      const {queryByText} = setup({anonymousState: 'full_anonymity'})
      expect(queryByText('Anonymous Discussion')).toBeInTheDocument()
    })

    it('clicking view availability opens the tray', () => {
      const container = setup()
      const viewAvailabilityButton = container.queryByText('View Availability')
      fireEvent.click(viewAvailabilityButton)
      expect(container.getByText('99')).toBeInTheDocument()
      expect(container.getByText('section 2')).toBeInTheDocument()
    })
  })
})
