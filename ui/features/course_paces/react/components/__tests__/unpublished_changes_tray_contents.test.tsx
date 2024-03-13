/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, act} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'

import {UnpublishedChangesTrayContents} from '../unpublished_changes_tray_contents'

const onTrayDismiss = jest.fn()
const onResetPace = jest.fn()

const CHANGES = [
  {id: 'theme', summary: 'You changed the theme from Light Mode to Dark Mode.'},
  {id: 'volume', summary: 'You changed the volume level from Palatable to Insanely High.'},
]

const defaultProps = {
  autoSaving: false,
  isSyncing: false,
  showLoadingOverlay: false,
  unpublishedChanges: CHANGES,
  onResetPace,
  handleTrayDismiss: onTrayDismiss,
}

beforeAll(() => {
  window.ENV.FEATURES ||= {}
  window.ENV.FEATURES.course_paces_redesign = true
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('UnpublishedChangesTrayContents', () => {
  it('renders the provided changes', () => {
    const {getByText} = render(<UnpublishedChangesTrayContents {...defaultProps} />)

    for (const change of CHANGES) {
      expect(getByText(change.summary)).toBeInTheDocument()
    }
  })

  it('renders successfully with no changes', () => {
    const {getByText} = render(
      <UnpublishedChangesTrayContents {...defaultProps} unpublishedChanges={[]} />
    )
    expect(getByText('Unpublished Changes')).toBeInTheDocument()
  })

  it('calls the handleTrayDismiss when the close button is clicked', async () => {
    const {getByText} = render(<UnpublishedChangesTrayContents {...defaultProps} />)

    const closeButton = getByText('Close')
    await userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never}).click(closeButton)
    expect(onTrayDismiss).toHaveBeenCalledWith(false)
  })

  it('disables the reset button if loading', () => {
    const {getByRole} = render(
      <UnpublishedChangesTrayContents {...defaultProps} isSyncing={true} />
    )
    const resetButton = getByRole('button', {name: 'Reset all'})
    expect(resetButton).toBeInTheDocument()
    expect(resetButton).toBeDisabled()
  })

  it('disables the reset button if there are no changes', () => {
    const {getByRole} = render(
      <UnpublishedChangesTrayContents {...defaultProps} unpublishedChanges={[]} />
    )
    const resetButton = getByRole('button', {name: 'Reset all'})
    expect(resetButton).toBeInTheDocument()
    expect(resetButton).toBeDisabled()
  })

  it('does nothing if reset is canceled in the modal', () => {
    const {getByRole, getByText} = render(<UnpublishedChangesTrayContents {...defaultProps} />)
    const resetButton = getByRole('button', {name: 'Reset all'})
    act(() => resetButton.click())
    expect(getByText('Reset all unpublished changes?')).toBeInTheDocument()
    expect(
      getByText('Your unpublished changes will be reverted to their previously saved state.')
    ).toBeInTheDocument()
    const cancelButton = getByRole('button', {name: 'Cancel'})
    act(() => cancelButton.click())
    expect(onResetPace).not.toHaveBeenCalled()
  })

  it('calls onResetPace and handleTrayDismiss when the reset is confirmed in the modal', () => {
    const {getByRole} = render(<UnpublishedChangesTrayContents {...defaultProps} />)
    const resetButton = getByRole('button', {name: 'Reset all'})
    act(() => resetButton.click())
    expect(onResetPace).not.toHaveBeenCalled()
    const cancelButton = getByRole('button', {name: 'Reset'})
    act(() => cancelButton.click())
    expect(onResetPace).toHaveBeenCalledTimes(1)
    expect(onTrayDismiss).toHaveBeenCalledWith(true)
  })

  it('does not render the reset all button if the course_paces_redesign flag is disabled', () => {
    window.ENV.FEATURES.course_paces_redesign = false
    const {getByText, queryByText} = render(<UnpublishedChangesTrayContents {...defaultProps} />)
    expect(getByText('Unpublished Changes')).toBeInTheDocument()
    expect(queryByText('Reset all')).not.toBeInTheDocument()
  })
})
