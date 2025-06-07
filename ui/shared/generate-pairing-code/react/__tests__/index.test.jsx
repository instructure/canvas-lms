// @vitest-environment jsdom
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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import GeneratePairingCode from '../index'

const defaultProps = {
  userId: '1',
}

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

it('renders the button and modal', () => {
  render(<GeneratePairingCode {...defaultProps} />)

  expect(screen.getByRole('button', {name: 'Pair with Observer'})).toBeInTheDocument()
  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
})

it('Shows the pairing code in the modal after clicking the button', async () => {
  const user = userEvent.setup()

  server.use(
    http.post('/api/v1/users/1/observer_pairing_codes', () => HttpResponse.json({code: '1234'})),
  )

  render(<GeneratePairingCode {...defaultProps} />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  await waitFor(() => {
    expect(screen.getByRole('dialog', {name: 'Pair with Observer'})).toBeInTheDocument()
  })

  await waitFor(() => {
    expect(screen.getByText('1234')).toBeInTheDocument()
  })
})

it('Show an error in the modal if the pairing code fails to generate', async () => {
  const user = userEvent.setup()

  server.use(
    http.post(
      '/api/v1/users/1/observer_pairing_codes',
      () => new HttpResponse(null, {status: 401}),
    ),
  )

  render(<GeneratePairingCode {...defaultProps} />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  await waitFor(() => {
    expect(screen.getByText('There was an error generating the pairing code')).toBeInTheDocument()
  })
})

it('Shows the loading spinner while the pairing code is being generated', async () => {
  const user = userEvent.setup()
  render(<GeneratePairingCode {...defaultProps} />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  expect(screen.getByText('Generating pairing code...')).toBeInTheDocument()
})

it('clicking the close button will close the modal', async () => {
  const user = userEvent.setup()

  server.use(
    http.post('/api/v1/users/1/observer_pairing_codes', () => HttpResponse.json({code: '1234'})),
  )

  render(<GeneratePairingCode {...defaultProps} />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  await waitFor(() => {
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  const closeButton = screen.getByRole('button', {name: /Close/})
  await user.click(closeButton)

  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
})

it('clicking the ok button will close the modal', async () => {
  const user = userEvent.setup()

  server.use(
    http.post('/api/v1/users/1/observer_pairing_codes', () => HttpResponse.json({code: '1234'})),
  )

  render(<GeneratePairingCode {...defaultProps} />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  await waitFor(() => {
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  const okButton = screen.getByRole('button', {name: 'OK'})
  await user.click(okButton)

  expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
})

it('should use the name in the text when it is provided', async () => {
  const user = userEvent.setup()

  server.use(
    http.post('/api/v1/users/1/observer_pairing_codes', () => HttpResponse.json({code: '1234'})),
  )

  render(<GeneratePairingCode {...defaultProps} name="George" />)

  const button = screen.getByRole('button', {name: 'Pair with Observer'})
  await user.click(button)

  await waitFor(() => {
    expect(screen.getByText(/George/)).toBeInTheDocument()
  })
})
