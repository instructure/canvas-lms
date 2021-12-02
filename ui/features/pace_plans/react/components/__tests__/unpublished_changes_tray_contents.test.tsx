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

import {act, render} from '@testing-library/react'
import UnpublishedChangesTrayContents from '../unpublished_changes_tray_contents'
import React from 'react'
import userEvent from '@testing-library/user-event'

const onTrayDismiss = jest.fn()
const CHANGES = [
  {id: 'theme', summary: 'You changed the theme from Light Mode to Dark Mode.'},
  {id: 'volume', summary: 'You changed the volume level from Palatable to Insanely High.'}
]

afterEach(() => {
  jest.clearAllMocks()
})

describe('UnpublishedChangesTrayContents', () => {
  it('renders the provided changes', () => {
    const {getByText} = render(
      <UnpublishedChangesTrayContents handleTrayDismiss={onTrayDismiss} changes={CHANGES} />
    )

    for (const change of CHANGES) {
      expect(getByText(change.summary)).toBeInTheDocument()
    }
  })

  it('renders successfully with no provided changes', () => {
    const {getByText} = render(<UnpublishedChangesTrayContents handleTrayDismiss={onTrayDismiss} />)
    expect(getByText('Unpublished Changes')).toBeInTheDocument()
  })

  it('calls the callback when the close button is clicked', () => {
    const {getByText} = render(<UnpublishedChangesTrayContents handleTrayDismiss={onTrayDismiss} />)

    const closeButton = getByText('Close')
    act(() => userEvent.click(closeButton))
    expect(onTrayDismiss).toHaveBeenCalled()
  })
})
