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

import {AssignmentDueDate} from '../AssignmentDueDate'

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

const mockProps = {
  dueDate: '2021-03-30T23:59:59-06:00',
  onSetDueDateTrayOpen: jest.fn(),
}

const setup = props => {
  return render(<AssignmentDueDate {...props} />)
}

describe('AssignmentDueDate', () => {
  describe('Desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'},
      }))
    })

    it('should render due date', () => {
      const container = setup(mockProps)
      expect(container.getByText('Due Mar 31, 2021 5:59am')).toBeInTheDocument()
    })

    it('should not find open due date tray button', () => {
      const container = setup(mockProps)
      expect(container.queryByTestId('mobile-due-date-tray-expansion')).toBeNull()
    })
  })
  describe('Tablet', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '1000px'},
      }))
    })

    it('should render due date', () => {
      const container = setup(mockProps)
      expect(container.getByText('Due Mar 31, 2021')).toBeInTheDocument()
    })

    it('should find open due date tray button', () => {
      const container = setup(mockProps)
      expect(container.queryByTestId('mobile-due-date-tray-expansion')).toBeInTheDocument()
    })
  })
})
