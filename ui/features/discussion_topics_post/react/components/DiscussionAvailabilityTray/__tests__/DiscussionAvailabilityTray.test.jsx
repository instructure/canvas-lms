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

import {render} from '@testing-library/react'
import React from 'react'
import {responsiveQuerySizes} from '../../../utils'
import {DiscussionAvailabilityTray} from '../DiscussionAvailabilityTray'

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

const mockAvailabilities = [
  {
    id: 'U2VjdGlvbi00',
    _id: '1',
    userCount: 99,
    name: 'section 2',
  },
]
const mockLockAt = '2022-01-19T23:59:59-07:00'
const mockDelayedPost = '2022-01-12T00:00:00-07:00'

const setup = props => {
  return render(
    <DiscussionAvailabilityTray
      lockAt={mockLockAt}
      delayedPostAt={mockDelayedPost}
      availabilities={mockAvailabilities}
      {...props}
    />
  )
}

describe('DiscussionAvailabilityTray', () => {
  describe('desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'},
      }))
    })

    it('displays tray and dates', () => {
      const {getByText} = setup()
      expect(getByText('Availability')).toBeInTheDocument()
      expect(getByText('99')).toBeInTheDocument()
      expect(getByText('section 2')).toBeInTheDocument()
      expect(getByText('Jan 12, 2022 7am')).toBeInTheDocument()
      expect(getByText('Jan 20, 2022 6:59am')).toBeInTheDocument()
    })

    it('correct text is shown when a date is not set', () => {
      const {getByText} = setup({
        lockAt: null,
        delayedPostAt: null,
      })
      expect(getByText('No Start Date')).toBeInTheDocument()
      expect(getByText('No End Date')).toBeInTheDocument()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '1000px'},
      }))
    })

    it('displays tray and correctly formatted dates', () => {
      const container = setup()
      expect(container.getByTestId('availability-table')).toBeInTheDocument()
      expect(container.getByText('99')).toBeInTheDocument()
      expect(container.getByText('section 2')).toBeInTheDocument()
      expect(container.getByText('Jan 12, 2022 7am')).toBeInTheDocument()
      expect(container.getByText('Jan 20, 2022 6:59am')).toBeInTheDocument()
    })

    it('correct text is shown when a date is not set', () => {
      const {getByText} = setup({
        lockAt: null,
        delayedPostAt: null,
      })
      expect(getByText('No Start Date')).toBeInTheDocument()
      expect(getByText('No End Date')).toBeInTheDocument()
    })
  })
})
