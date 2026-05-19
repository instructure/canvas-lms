// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import * as CanvasReact from '@canvas/react'
import AsyncComponents from '../../default_gradebook/AsyncComponents'
import {showMessageStudentsWithObserversModal} from '../MessageStudentsWithObserversModal'

const FakeDialog = ({onClose, assignment}: {onClose: () => void; assignment?: {id: string}}) => (
  <div data-testid="fake-dialog">
    {assignment?.id && <span data-testid="assignment-id">{assignment.id}</span>}
    <button onClick={onClose}>Close</button>
  </div>
)

describe('showMessageStudentsWithObserversModal', () => {
  let mountPoint: HTMLElement
  let loadDialogSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    mountPoint = document.createElement('span')
    mountPoint.setAttribute('data-component', 'MessageStudentsWithObserversModal')
    document.body.appendChild(mountPoint)

    vi.spyOn(CanvasReact, 'legacyRender').mockImplementation((el, container) => {
      render(el, {container})
    })
    vi.spyOn(CanvasReact, 'legacyUnmountComponentAtNode').mockImplementation(container => {
      render(<></>, {container})
    })
    loadDialogSpy = vi
      .spyOn(AsyncComponents, 'loadMessageStudentsWithObserversDialog')
      .mockResolvedValue(FakeDialog)
  })

  afterEach(() => {
    mountPoint.remove()
    vi.clearAllMocks()
  })

  it('renders the dialog into the mount point when it exists', async () => {
    await showMessageStudentsWithObserversModal({}, () => {})
    expect(screen.getByTestId('fake-dialog')).toBeInTheDocument()
    expect(mountPoint.contains(screen.getByTestId('fake-dialog'))).toBe(true)
  })

  it('does not render when the mount point is absent', async () => {
    mountPoint.remove()
    await showMessageStudentsWithObserversModal({}, () => {})
    expect(screen.queryByTestId('fake-dialog')).not.toBeInTheDocument()
  })

  it('passes props through to the dialog', async () => {
    await showMessageStudentsWithObserversModal({assignment: {id: 'abc-123'}}, () => {})
    expect(screen.getByTestId('assignment-id')).toHaveTextContent('abc-123')
  })

  it('unmounts the dialog and calls focusAtEnd when Close is clicked', async () => {
    const focusAtEnd = vi.fn()
    await showMessageStudentsWithObserversModal({}, focusAtEnd)
    expect(screen.getByTestId('fake-dialog')).toBeInTheDocument()

    await userEvent.click(screen.getByRole('button', {name: 'Close'}))

    expect(screen.queryByTestId('fake-dialog')).not.toBeInTheDocument()
    expect(focusAtEnd).toHaveBeenCalledTimes(1)
  })
})
