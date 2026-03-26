/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {AuthProvider} from '../AuthProvider'
import type {AuthProviderCard} from '../../types'

const makeCard = (overrides: Partial<AuthProviderCard> = {}): AuthProviderCard => ({
  id: 'card-1',
  label: 'Students',
  authentication_provider_id: 1,
  icon: undefined,
  ...overrides,
})

const defaultProps = () => ({
  card: makeCard(),
  isEditing: true,
  isDisabled: false,
  authProviders: [{id: '1', url: 'https://sso.example.com', auth_type: 'saml'}],
  onEditStart: vi.fn(),
  onEditDone: vi.fn(),
  onEditCancel: vi.fn(),
  onDelete: vi.fn(),
  onMoveUp: vi.fn(),
  onMoveDown: vi.fn(),
})

describe('AuthProvider label validation', () => {
  it('shows error when label contains script tags', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: '<script>alert(1)</script>'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(screen.getByText(/must not contain/)).toBeInTheDocument()
    expect(props.onEditDone).not.toHaveBeenCalled()
  })

  it('shows error when label contains img tag with event handler', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: '<img src=x onerror=alert(1)>'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(screen.getByText(/must not contain/)).toBeInTheDocument()
    expect(props.onEditDone).not.toHaveBeenCalled()
  })

  it('shows error when label contains double-quote attribute injection', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: '" onclick="alert(\'xss\')"'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(screen.getByText(/must not contain/)).toBeInTheDocument()
    expect(props.onEditDone).not.toHaveBeenCalled()
  })

  it('shows error when label contains angle brackets without full tags', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: 'Click > here < now'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(screen.getByText(/must not contain/)).toBeInTheDocument()
    expect(props.onEditDone).not.toHaveBeenCalled()
  })

  it('accepts plain text label', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: 'Students'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(props.onEditDone).toHaveBeenCalledWith(expect.objectContaining({label: 'Students'}))
  })

  it('accepts label with single quotes', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: "Students' Portal"})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(props.onEditDone).toHaveBeenCalledWith(
      expect.objectContaining({label: "Students' Portal"}),
    )
  })

  it('accepts label with ampersand', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: 'Arts & Sciences'})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(props.onEditDone).toHaveBeenCalledWith(
      expect.objectContaining({label: 'Arts & Sciences'}),
    )
  })

  it('shows error when label is empty', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.card = makeCard({label: ''})
    render(<AuthProvider {...props} />)
    await user.click(screen.getByTestId('auth-provider-done-button'))
    expect(screen.getByText('Label is required')).toBeInTheDocument()
    expect(props.onEditDone).not.toHaveBeenCalled()
  })
})

describe('AuthProviderForm maxLength', () => {
  it('sets maxLength on the login label input', () => {
    const props = defaultProps()
    render(<AuthProvider {...props} />)
    const input = screen.getByLabelText('Login Button Text')
    expect(input).toHaveAttribute('maxLength', '255')
  })
})
