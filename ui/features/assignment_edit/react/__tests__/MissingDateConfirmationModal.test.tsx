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

import React from 'react'
import {act, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MissingDateConfirmationModal from '../MissingDateConfirmationModal'
import type {MissingDateConfirmationModalHandle} from '../MissingDateConfirmationModal'

function renderModal(overrides: {onContinue?: () => void; onGoBack?: () => void} = {}) {
  const ref = React.createRef<MissingDateConfirmationModalHandle>()
  render(
    <MissingDateConfirmationModal
      ref={ref}
      onContinue={overrides.onContinue}
      onGoBack={overrides.onGoBack}
    />,
  )
  return ref
}

describe('MissingDateConfirmationModal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('does not render content when closed', () => {
    renderModal()
    expect(screen.queryByText('Warning')).not.toBeInTheDocument()
  })

  it('renders the warning title when opened', () => {
    const ref = renderModal()
    act(() => ref.current!.open())
    expect(screen.getByText('Warning')).toBeInTheDocument()
  })

  it('renders the warning message', () => {
    const ref = renderModal()
    act(() => ref.current!.open())
    expect(screen.getByText('Not everyone will be assigned this item!')).toBeInTheDocument()
    expect(screen.getByText('Would you like to continue?')).toBeInTheDocument()
  })

  it('renders Go Back and Continue buttons', () => {
    const ref = renderModal()
    act(() => ref.current!.open())
    expect(screen.getByText('Go Back')).toBeInTheDocument()
    expect(screen.getByText('Continue')).toBeInTheDocument()
  })

  it('calls onContinue and closes when Continue is clicked', async () => {
    const user = userEvent.setup()
    const onContinue = vi.fn()
    const ref = renderModal({onContinue})
    act(() => ref.current!.open())
    const btn = screen.getByText('Continue').closest('button') as HTMLElement
    await user.click(btn)
    expect(onContinue).toHaveBeenCalledTimes(1)
    await waitFor(() => {
      expect(screen.queryByText('Warning')).not.toBeInTheDocument()
    })
  })

  it('calls onGoBack and closes when Go Back is clicked', async () => {
    const user = userEvent.setup()
    const onGoBack = vi.fn()
    const ref = renderModal({onGoBack})
    act(() => ref.current!.open())
    const btn = screen.getByText('Go Back').closest('button') as HTMLElement
    await user.click(btn)
    expect(onGoBack).toHaveBeenCalledTimes(1)
    await waitFor(() => {
      expect(screen.queryByText('Warning')).not.toBeInTheDocument()
    })
  })

  it('can be closed programmatically via ref', async () => {
    const ref = renderModal()
    act(() => ref.current!.open())
    expect(screen.getByText('Warning')).toBeInTheDocument()
    act(() => ref.current!.close())
    await waitFor(() => {
      expect(screen.queryByText('Warning')).not.toBeInTheDocument()
    })
  })
})
