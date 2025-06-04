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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigureExternalToolButton from '../ConfigureExternalToolButton'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

let tool
let event
let ref
let returnFocus

beforeEach(() => {
  ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  ENV.CONTEXT_BASE_URL = 'https://advantage.tool.com'
  tool = {
    name: 'test tool',
    app_id: '1',
    tool_configuration: {
      url: 'https://advantage.tool.com',
    },
  }
  event = {
    preventDefault() {},
  }
  ref = React.createRef()
  returnFocus = jest.fn()
  userEvent.setup()
})

function renderComponent(modalIsOpen = false) {
  return render(<ConfigureExternalToolButton {...{tool, modalIsOpen, returnFocus, ref}} />)
}

function renderComponentOpen() {
  renderComponent(true)
}

test('uses the tool id to launch', () => {
  renderComponentOpen()
  expect(screen.getByTitle(/Tool Configuration/i).getAttribute('src')).toContain(
    '/external_tools/1',
  )
})

test('includes the tool_configuration placement', () => {
  renderComponentOpen()
  expect(screen.getByTitle(/Tool Configuration/i).getAttribute('src')).toContain(
    'placement=tool_configuration',
  )
})

test('adds iframe width/height when it is in the tool configuration', () => {
  tool.tool_configuration.selection_width = 500
  tool.tool_configuration.selection_height = 600
  renderComponentOpen()
  expect(ref.current.iframeStyle()).toEqual({
    border: 'none',
    padding: '2px',
    width: 500,
    height: 600,
    minHeight: 600,
  })
})

test('sets the iframe allowances', () => {
  renderComponentOpen()
  const iframe = screen.getByTitle(/Tool Configuration/i)
  expect(iframe).toHaveAttribute('allow', 'midi; media')
})

test("sets the 'data-lti-launch' attribute on the iframe", () => {
  renderComponentOpen()
  const iframe = screen.getByTitle(/Tool Configuration/i)
  expect(iframe).toHaveAttribute('data-lti-launch', 'true')
})

test('opens and closes the modal', async () => {
  renderComponent()
  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()

  await userEvent.click(screen.getByText(/configure/i))

  expect(screen.getByRole('dialog')).toBeInTheDocument()

  await userEvent.click(screen.getByTestId('close-modal-button'))

  await waitFor(() => {
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })
  expect(returnFocus).toHaveBeenCalled()
})

test('closes the modal when tool sends lti.close message', async () => {
  renderComponentOpen()
  monitorLtiMessages()

  fireEvent(
    window,
    new MessageEvent('message', {
      data: {subject: 'lti.close'},
      origin: 'https://advantage.tool.com',
      source: window,
    }),
  )

  await waitFor(() => {
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })
})
