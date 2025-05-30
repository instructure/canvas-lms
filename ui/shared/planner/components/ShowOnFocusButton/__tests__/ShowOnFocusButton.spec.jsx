/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ShowOnFocusButton from '../index'

it('renders a ScreenReaderContent by default', () => {
  const {getByTestId, getByRole} = render(<ShowOnFocusButton>Button</ShowOnFocusButton>)

  // Should render ScreenReaderContent as the root element
  expect(getByTestId('screenreader-content')).toBeInTheDocument()

  // Should contain a button
  const button = getByRole('button')
  expect(button).toBeInTheDocument()
  expect(button).toHaveTextContent('Button')
})

it('renders a Button when it has focus', () => {
  const {getByRole, queryByRole} = render(<ShowOnFocusButton>Button</ShowOnFocusButton>)
  const buttonElement = getByRole('button')
  fireEvent.focus(buttonElement)
  const screenReaderContent = queryByRole('a')
  expect(screenReaderContent).not.toBeInTheDocument()
})

it('renders ScreenReaderContent after blur', () => {
  const {getByRole, queryByTestId} = render(<ShowOnFocusButton>Button</ShowOnFocusButton>)

  const buttonElement = getByRole('button')

  // Initially, there should be ScreenReaderContent
  expect(queryByTestId('screenreader-content')).toBeInTheDocument()

  fireEvent.focus(buttonElement)

  // After focus, ScreenReaderContent should not be present
  expect(queryByTestId('screenreader-content')).not.toBeInTheDocument()

  // The button should still exist and be visible
  expect(getByRole('button')).toBeInTheDocument()
})
