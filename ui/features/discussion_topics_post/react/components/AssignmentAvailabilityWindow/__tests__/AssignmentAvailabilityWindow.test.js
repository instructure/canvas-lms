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

import {AssignmentAvailabilityWindow} from '../AssignmentAvailabilityWindow'

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

const mockProps = ({
  availableDate = '2021-03-24T00:00:00-06:00',
  untilDate = '2021-04-03T23:59:59-06:00',
  showOnMobile = false,
  showDateWithTime = false,
  anonymousState = null,
} = {}) => ({
  availableDate,
  untilDate,
  showOnMobile,
  showDateWithTime,
  anonymousState,
})

const setup = props => {
  return render(<AssignmentAvailabilityWindow {...props} />)
}

describe('AssignmentAvailabilityWindow', () => {
  describe('Desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'},
      }))
    })

    it('should render availability window', () => {
      const container = setup(mockProps())
      expect(
        container.getByText('Available from Mar 24, 2021 until Apr 4, 2021')
      ).toBeInTheDocument()
    })

    it('should render availability window with time', () => {
      const container = setup(mockProps({showDateWithTime: true}))
      expect(
        container.getByText('Available from Mar 24, 2021 6am until Apr 4, 2021 5:59am')
      ).toBeInTheDocument()
    })

    it('should render availability window with time with pipe', () => {
      const container = setup(mockProps({showDateWithTime: true, anonymousState: 'full_anonymity'}))
      expect(
        container.getByText('| Available from Mar 24, 2021 6am until Apr 4, 2021 5:59am')
      ).toBeInTheDocument()
    })

    it('should render only from section', () => {
      const container = setup(mockProps({untilDate: ''}))
      expect(container.getByText('Available from Mar 24, 2021')).toBeInTheDocument()
    })

    it('should render only until section', () => {
      const container = setup(mockProps({availableDate: ''}))
      expect(container.getByText('Available until Apr 4, 2021')).toBeInTheDocument()
    })

    it('should render only until section with pipe', () => {
      const container = setup(mockProps({availableDate: '', anonymousState: 'full_anonymity'}))
      expect(container.getByText('| Available until Apr 4, 2021')).toBeInTheDocument()
    })
  })

  describe('Tablet', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '1000px'},
      }))
    })

    it('should not render availability window', () => {
      const container = setup(mockProps())
      expect(container.queryByText('Available from Mar 24, 2021 until Apr 4, 2021')).toBeNull()
    })

    it('should render availability window when showOnMobile is true', () => {
      const container = setup(mockProps({showOnMobile: true}))
      expect(
        container.queryByText('Available from Mar 24, 2021 until Apr 4, 2021')
      ).toBeInTheDocument()
    })
  })
})
