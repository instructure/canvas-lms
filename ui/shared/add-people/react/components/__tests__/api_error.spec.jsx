/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import ApiError from '../api_error'
import {render} from '@testing-library/react'

describe('ApiError', () => {
  test('renders error when passed as a string', () => {
    const wrapper = render(<ApiError error="show me" />)
    expect(wrapper.queryByText('show me')).toBeInTheDocument()
  })

  test('renders error when passed as an array of strings', () => {
    const wrapper = render(<ApiError error={['first', 'second']} />)
    expect(wrapper.queryByText('The following users could not be created.')).toBeInTheDocument()
    expect(wrapper.queryByText('first')).toBeInTheDocument()
    expect(wrapper.queryByText('second')).toBeInTheDocument()
  })
})
