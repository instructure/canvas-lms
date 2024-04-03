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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigureExternalToolButton from '../ConfigureExternalToolButton'

let tool
let event

beforeEach(() => {
  ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  ENV.CONTEXT_BASE_URL = 'https://advantage.tool.com'
  tool = {
    name: 'test tool',
    tool_configuration: {
      url: 'https://advantage.tool.com',
    },
  }
  event = {
    preventDefault() {},
  }
  userEvent.setup()
})

test('uses the tool configuration "url" when present', () => {
  render(<ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} />)
  expect(screen.getByTitle(/Tool Configuration/i).getAttribute('src')).toContain(
    'url=https%3A%2F%2Fadvantage.tool.com'
  )
})

test('uses the tool configuration "target_link_uri" when "url" is not present', () => {
  tool.tool_configuration = {
    target_link_uri: 'https://advantage.tool.com',
  }
  render(<ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} />)
  expect(screen.getByTitle(/Tool Configuration/i).getAttribute('src')).toContain(
    'url=https%3A%2F%2Fadvantage.tool.com'
  )
})

test('includes the tool_configuration placement', () => {
  render(<ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} />)
  expect(screen.getByTitle(/Tool Configuration/i).getAttribute('src')).toContain(
    'placement=tool_configuration'
  )
})

test('shows beginning info alert and adds styles to iframe', () => {
  const ref = React.createRef()
  render(
    <ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} ref={ref} />
  )
  ref.current.handleAlertFocus({target: {className: 'before'}})
  expect(ref.current.state.beforeExternalContentAlertClass).toEqual('')
  // Note: The width here is normally 300px, but because these are older JS files, the CSS isn't included,
  // so the offsetWidth is 0.
  expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
})

test('shows ending info alert and adds styles to iframe', () => {
  const ref = React.createRef()
  render(
    <ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} ref={ref} />
  )

  ref.current.handleAlertFocus({target: {className: 'after'}})
  expect(ref.current.state.afterExternalContentAlertClass).toEqual('')
  // Note: The width here is normally 300px, but because these are older JS files, the CSS isn't included,
  // so the offsetWidth is 0.
  expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
})

test('hides beginning info alert and adds styles to iframe', async () => {
  const ref = React.createRef()
  render(<ConfigureExternalToolButton tool={tool} returnFocus={jest.fn()} ref={ref} />)
  ref.current.openModal(event)
  ref.current.handleAlertBlur({target: {className: 'before'}})
  expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
  expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
})

test('hides ending info alert and adds styles to iframe', () => {
  const ref = React.createRef()
  render(<ConfigureExternalToolButton tool={tool} returnFocus={jest.fn()} ref={ref} />)
  ref.current.openModal(event)

  ref.current.handleAlertBlur({target: {className: 'after'}})
  expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
  expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
})

test("doesn't show alerts or add border to iframe by default", () => {
  const ref = React.createRef()
  render(<ConfigureExternalToolButton tool={tool} returnFocus={jest.fn()} ref={ref} />)
  ref.current.openModal(event)
  const iframe = screen.getByTitle(/Tool Configuration/i)
  expect(iframe).toHaveClass('tool_launch')
  expect(iframe).not.toHaveStyle('border: 2px solid #0374B5;')
})

test('sets the iframe allowances', () => {
  const ref = React.createRef()
  render(
    <ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} ref={ref} />
  )
  ref.current.handleAlertFocus({target: {className: 'before'}})
  const iframe = screen.getByTitle(/Tool Configuration/i)
  expect(iframe).toHaveAttribute('allow', 'midi; media')
})

test("sets the 'data-lti-launch' attribute on the iframe", () => {
  render(<ConfigureExternalToolButton tool={tool} modalIsOpen={true} returnFocus={jest.fn()} />)
  const iframe = screen.getByTitle(/Tool Configuration/i)
  expect(iframe).toHaveAttribute('data-lti-launch', 'true')
})

test('opens and closes the modal', async () => {
  const returnFocus = jest.fn()
  render(<ConfigureExternalToolButton tool={tool} returnFocus={returnFocus} />)
  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()

  await userEvent.click(screen.getByText(/configure/i))

  expect(screen.getByRole('dialog')).toBeInTheDocument()

  await userEvent.click(screen.getByTestId('close-modal-button'))

  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  expect(returnFocus).toHaveBeenCalled()
})
