// @vitest-environment jsdom
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import AllowedAttempts from '../AllowedAttempts'

function renderAllowedAttempts(opts) {
  const defaults = {
    limited: false,
    attempts: 42,
    onLimitedChange: jest.fn(),
    onAttemptsChange: jest.fn(),
    onHideErrors: jest.fn(),
  }

  return {...render(<AllowedAttempts {...defaults} {...opts} />), ...defaults, ...opts}
}

it('renders limited attempts with proper field values', () => {
  const {getByLabelText} = renderAllowedAttempts({limited: true})
  expect(getByLabelText(/allowed attempts/i).value).toBe('limited')
  expect(getByLabelText(/number of attempts/i).value).toBe('42')
})

it('renders number of attempts as hidden with a value of -1 when limited is false', () => {
  const {getByLabelText} = renderAllowedAttempts()
  expect(getByLabelText(/allowed attempts/i).value).toBe('unlimited')
  const numberInput = getByLabelText(/number of attempts/i)
  expect(numberInput).not.toBeVisible()
  expect(numberInput.value).toBe('-1')
})

it('calls onLimitedChange when the option is changed', () => {
  const {getByLabelText, onLimitedChange} = renderAllowedAttempts()
  const input = getByLabelText(/allowed attempts/i)
  fireEvent.change(input, {target: {value: 'limited'}})
  expect(onLimitedChange).toHaveBeenCalledWith(true)
})

it('calls onHideErrors when the option is changed', () => {
  const {getByLabelText, onHideErrors} = renderAllowedAttempts()
  const input = getByLabelText(/allowed attempts/i)
  fireEvent.change(input, {target: {value: 'limited'}})
  expect(onHideErrors).toHaveBeenCalled()
})

it('calls onAttemptsChange with a numeric value when the input value changes', () => {
  const {getByLabelText, onAttemptsChange} = renderAllowedAttempts({limited: true})
  const input = getByLabelText(/number of attempts/i)
  fireEvent.change(input, {target: {value: '3'}})
  expect(onAttemptsChange).toHaveBeenCalledWith(3)
})

it('calls onHideErrors when the input value changes', () => {
  const {getByLabelText, onHideErrors} = renderAllowedAttempts()
  const input = getByLabelText(/number of attempts/i)
  fireEvent.change(input, {target: {value: '3'}})
  expect(onHideErrors).toHaveBeenCalled()
})

it('calls onAttemptsChange with null when the input value becomes blank', () => {
  const {getByLabelText, onAttemptsChange} = renderAllowedAttempts({limited: true})
  const input = getByLabelText(/number of attempts/i)
  fireEvent.change(input, {target: {value: ''}})
  expect(onAttemptsChange).toHaveBeenCalledWith(null)
})

it('does not call onAttemptsChange when value is NaN', () => {
  const {getByLabelText, onAttemptsChange} = renderAllowedAttempts({limited: true})
  const input = getByLabelText(/number of attempts/i)
  fireEvent.change(input, {target: {value: 'abc'}})
  expect(onAttemptsChange).not.toHaveBeenCalled()
})

it('calls onAttemptsChange when incremented', () => {
  const {onAttemptsChange} = renderAllowedAttempts({limited: true})
  fireEvent.mouseDown(document.querySelectorAll('button')[0])
  expect(onAttemptsChange).toHaveBeenCalledWith(43)
})

it('calls onHideErrors when incremented', () => {
  const {onHideErrors} = renderAllowedAttempts({limited: true})
  fireEvent.mouseDown(document.querySelectorAll('button')[0])
  expect(onHideErrors).toHaveBeenCalled()
})

it('calls onAttemptsChange when decremented', () => {
  const {onAttemptsChange} = renderAllowedAttempts({limited: true})
  fireEvent.mouseDown(document.querySelectorAll('button')[1])
  expect(onAttemptsChange).toHaveBeenCalledWith(41)
})

it('calls onHideErrors when incremented', () => {
  const {onHideErrors} = renderAllowedAttempts({limited: true})
  fireEvent.mouseDown(document.querySelectorAll('button')[1])
  expect(onHideErrors).toHaveBeenCalled()
})

it('does not allow decrement below one', () => {
  const {onAttemptsChange} = renderAllowedAttempts({limited: true, attempts: 1})
  fireEvent.mouseDown(document.querySelectorAll('button')[1])
  expect(onAttemptsChange).toHaveBeenCalledWith(1)
})

it('handles increment when attempts is null', () => {
  const {onAttemptsChange} = renderAllowedAttempts({limited: true, attempts: null})
  fireEvent.mouseDown(document.querySelectorAll('button')[0])
  expect(onAttemptsChange).toHaveBeenCalledWith(1)
})

it('handles decrement when attempts is null', () => {
  const {onAttemptsChange} = renderAllowedAttempts({limited: true, attempts: null})
  fireEvent.mouseDown(document.querySelectorAll('button')[1])
  expect(onAttemptsChange).toHaveBeenCalledWith(1)
})
