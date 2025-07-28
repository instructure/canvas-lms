/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import React from 'react'
import ReviewsPerUserInput from '../ReviewsPerUserInput'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock jQuery to prevent flashError errors from unrelated components
jest.mock('jquery', () => {
  const jQueryMock = {
    flashError: jest.fn(),
    Deferred: jest.fn(() => ({
      resolve: jest.fn(),
      reject: jest.fn(),
      promise: jest.fn(),
    })),
  }
  return jest.fn(() => jQueryMock)
})

describe('ReviewsPerUserInput Tests', () => {
  let onChangeMock: (value: string) => void

  beforeEach(() => {
    fakeENV.setup()
    onChangeMock = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  const props = (overrides = {}) => {
    return {
      initialCount: '',
      onChange: onChangeMock,
      ...overrides,
    }
  }

  it('input displays initial reviews per user count', () => {
    const {getByTestId} = render(<ReviewsPerUserInput {...props({initialCount: '1'})} />)
    expect(getByTestId('reviews_per_user_input')).toHaveValue('1')
  })

  it('error text is displayed if value is less than 0', async () => {
    const {getByTestId, getByText} = render(<ReviewsPerUserInput {...props()} />)
    const input = getByTestId('reviews_per_user_input')
    await userEvent.type(input, '-2')
    await userEvent.tab()
    expect(getByText('Must be greater than 0')).toBeInTheDocument()
  })

  it('error text is displayed if value is 0', async () => {
    const {getByTestId, getByText} = render(<ReviewsPerUserInput {...props()} />)
    const input = getByTestId('reviews_per_user_input')
    await userEvent.type(input, '0')
    await userEvent.tab()
    expect(getByText('Must be greater than 0')).toBeInTheDocument()
  })

  it('error text is displayed if value is not an integer', async () => {
    const {getByTestId, getByText} = render(<ReviewsPerUserInput {...props()} />)
    const input = getByTestId('reviews_per_user_input')
    await userEvent.type(input, '1.2')
    await userEvent.tab()
    expect(getByText('Must be a whole number')).toBeInTheDocument()
  })

  it('onChange is called when input changes', async () => {
    const {getByTestId} = render(<ReviewsPerUserInput {...props()} />)
    const input = getByTestId('reviews_per_user_input')
    await userEvent.type(input, '1')
    expect(onChangeMock).toHaveBeenCalled()
  })
})
