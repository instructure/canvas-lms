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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {ThreadPagination} from '../ThreadPagination'

const defaultProps = overrides => ({
  setPage: jest.fn(),
  selectedPage: 1,
  totalPages: 10,
  ...overrides,
})

describe('ThreadPagination', () => {
  it('Uses the setPage callback with the correct argument', () => {
    const props = defaultProps()
    const {getByText} = render(<ThreadPagination {...props} />)

    fireEvent.click(getByText('2'))
    expect(props.setPage).toHaveBeenCalledWith(1)

    fireEvent.click(getByText('3'))
    expect(props.setPage).toHaveBeenCalledWith(2)

    fireEvent.click(getByText('10'))
    expect(props.setPage).toHaveBeenCalledWith(9)
  })
})
