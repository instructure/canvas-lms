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

import React from 'react'
import {render} from '@testing-library/react'
import GraderCountNumberInput from '../GraderCountNumberInput'
import userEvent from '@testing-library/user-event'

describe('GraderCountNumberInput', () => {
  let props
  let wrapper

  function numberInputContainer() {
    return wrapper.container.querySelector('.ModeratedGrading__GraderCountInputContainer')
  }

  function numberInput() {
    return numberInputContainer().querySelector('input')
  }

  function mountComponent() {
    wrapper = render(<GraderCountNumberInput {...props} />)
  }

  beforeEach(() => {
    props = {
      currentGraderCount: null,
      locale: 'en',
      availableGradersCount: 10,
    }
  })

  test('renders an input', () => {
    mountComponent()
    expect(numberInput()).toBeInTheDocument()
  })

  test('initializes grader count to currentGraderCount', () => {
    props.currentGraderCount = 6
    mountComponent()
    expect(numberInput().value).toBe('6')
  })

  test('initializes count to 2 if currentGraderCount is not present and availableGradersCount is > 1', () => {
    mountComponent()
    expect(numberInput().value).toBe('2')
  })

  test('initializes count to availableGradersCount if currentGraderCount is not present and availableGradersCount is < 2', () => {
    props.availableGradersCount = 1
    mountComponent()
    expect(numberInput().value).toBe('1')
  })

  test('accepts the entered value if it is a positive, whole number', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}5')
    expect(numberInput().value).toBe('5')
  })

  test('accepts the entered value if it is the empty string', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}')
    expect(numberInput().value).toBe('')
  })

  test('ignores the negative sign if a negative number is entered', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}-5')
    expect(numberInput().value).toBe('5')
  })

  test('ignores the decimal if a fractional number is entered', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}5.8')
    expect(numberInput().value).toBe('58')
  })

  test('ignores the input alltogether if the value entered is not numeric', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), 'a')
    expect(numberInput().value).toBe('2')
  })

  test('shows an error message if the grader count is 0', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}0')
    expect(numberInputContainer().textContent).toContain('Must have at least 1 grader')
  })

  test('shows a message if the grader count is > the max', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}11')
    expect(numberInputContainer().textContent).toContain('There are currently 10 available graders')
  })

  test('shows a message with correct grammar if the grader count is > the max and the max is 1', async () => {
    const user = userEvent.setup()
    props.availableGradersCount = 1
    mountComponent()
    await user.type(numberInput(), '{backspace}2')
    expect(numberInputContainer().textContent).toContain('There is currently 1 available grader')
  })

  test('shows an error message on blur if the grader count is the empty string', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}')
    numberInput().blur()
    expect(numberInputContainer().textContent).toContain('Must have at least 1 grader')
  })

  test('does not pass any validation error messages to the NumberInput if the input is valid', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.type(numberInput(), '{backspace}4')
    expect(numberInputContainer().textContent).toBe('Number of graders')
  })
})
