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

import {AssignmentContext} from '../AssignmentContext'

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

const mockProps = ({group = 'group 1'} = {}) => ({group})

const setup = props => {
  return render(<AssignmentContext {...props} />)
}

describe('AssignmentContext', () => {
  describe('Desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'},
      }))
    })

    it('should render context', () => {
      const container = setup(mockProps())
      expect(container.getByText('group 1')).toBeInTheDocument()
    })

    it('should render "Everyone" as context when no context is provided', () => {
      const container = setup(mockProps({group: ''}))
      expect(container.getByText('Everyone')).toBeInTheDocument()
    })
  })

  describe('Tablet', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '1000px'},
      }))
    })

    it('should render not render context', () => {
      const container = setup(mockProps())
      expect(container.queryByText('group 1')).toBeNull()
    })
  })
})
