/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {Pin} from '../Pin'

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

const setup = (props = {}) => {
  const defaultProps = {
    onClick: jest.fn(),
  }

  return render(<Pin {...defaultProps} {...props} />)
}

describe('Pin', () => {
  it('renders text', () => {
    const {getAllByText} = setup()
    expect(getAllByText('Pin')).toBeTruthy()
  })

  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getAllByText} = setup({onClick: onClickMock})

    expect(onClickMock.mock.calls).toHaveLength(0)
    fireEvent.click(getAllByText('Pin')[0])
    expect(onClickMock.mock.calls).toHaveLength(1)
  })
})
