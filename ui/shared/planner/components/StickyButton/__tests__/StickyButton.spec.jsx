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
import StickyButton from '../index'

it('renders', () => {
  const {container, getByRole, getByText} = render(
    <StickyButton id="sb">I am a Sticky Button</StickyButton>,
  )

  // Should render a span containing a button
  expect(container.querySelector('span')).toBeInTheDocument()

  // Should render button with correct attributes
  const button = getByRole('button')
  expect(button).toBeInTheDocument()
  expect(button).toHaveAttribute('id', 'sb')
  expect(button).toHaveAttribute('type', 'button')
  expect(button).not.toHaveAttribute('aria-disabled')
  expect(button).not.toHaveAttribute('aria-hidden')
  expect(button).not.toHaveAttribute('aria-describedby')

  // Should have the correct class names
  expect(button).toHaveClass('StickyButton-styles__root')
  expect(button).toHaveClass('StickyButton-styles__newActivityButton')

  // Should render children within layout span
  const layoutSpan = container.querySelector('span.StickyButton-styles__layout')
  expect(layoutSpan).toBeInTheDocument()
  expect(getByText('I am a Sticky Button')).toBeInTheDocument()
})

it('calls the onClick prop when clicked', () => {
  const fakeOnClick = jest.fn()
  const {getByRole} = render(
    <StickyButton id="sb" onClick={fakeOnClick}>
      Click me
    </StickyButton>,
  )

  fireEvent.click(getByRole('button'))
  expect(fakeOnClick).toHaveBeenCalled()
})

it('does not call the onClick prop when disabled', () => {
  const fakeOnClick = jest.fn()
  const {getByRole} = render(
    <StickyButton id="sb" onClick={fakeOnClick} disabled={true}>
      Disabled button
    </StickyButton>,
  )

  fireEvent.click(getByRole('button'))
  expect(fakeOnClick).not.toHaveBeenCalled()
})

it('renders the correct up icon', () => {
  const {container} = render(
    <StickyButton id="sb" direction="up">
      Click me
    </StickyButton>,
  )
  // Check if the up arrow icon is rendered
  const upIcon =
    container.querySelector('svg[name="IconArrowUp"]') ||
    container.querySelector('[data-testid="icon-arrow-up"]')
  expect(upIcon).toBeInTheDocument()
})

it('renders the correct down icon', () => {
  const {container} = render(
    <StickyButton id="sb" direction="down">
      Click me
    </StickyButton>,
  )
  // Check if the down arrow icon is rendered
  const downIcon =
    container.querySelector('svg[name="IconArrowDown"]') ||
    container.querySelector('[data-testid="icon-arrow-down"]')
  expect(downIcon).toBeInTheDocument()
})

it('adds aria-hidden when specified', () => {
  const {getByRole} = render(
    <StickyButton id="sb" hidden={true}>
      Click me
    </StickyButton>,
  )

  const button = getByRole('button', {hidden: true})
  expect(button).toHaveAttribute('aria-hidden', 'true')
})

it('shows aria-describedby when a description is given', () => {
  const {getByRole, container} = render(
    <StickyButton id="sb" description="hello world">
      Click me
    </StickyButton>,
  )
  expect(getByRole('button')).toHaveAttribute('aria-describedby', 'sb_desc')
  expect(container.querySelector('#sb_desc')).toBeInTheDocument()
})
