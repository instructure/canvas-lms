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

import {Errors, type ErrorsProps} from '../errors'
import {act, render} from '@testing-library/react'
import React from 'react'
import userEvent from '@testing-library/user-event'

const syncUnpublishedChanges = jest.fn()
afterEach(jest.clearAllMocks)

describe('Errors', () => {
  const defaultProps: ErrorsProps = {
    errors: {
      publish: 'TypeError: Failed to fetch',
      loading: 'TypeError: Failed to fetch',
      darkMode: 'E_THEME_TOO_DARK: Theme too dark, user could trip and fall',
    },
    responsiveSize: 'large',
    syncUnpublishedChanges,
  }

  it('renders nothing when there are no errors', () => {
    const {container} = render(<Errors {...defaultProps} errors={{}} />)

    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('displays custom error messages for pre-defined categories, and generic error messages for unknown categories', () => {
    const {getAllByText} = render(<Errors {...defaultProps} />)

    for (const error of [
      ...getAllByText('There was an error publishing your course pace.'),
      ...getAllByText('There was an error loading the pace.'),
      ...getAllByText('An error has occurred.'),
    ]) {
      expect(error).toBeInTheDocument()
    }
  })

  it('triggers a re-publish when the retry button is clicked', async () => {
    const {getByRole} = render(<Errors {...defaultProps} />)

    await userEvent.click(getByRole('button', {name: 'Retry'}))
    expect(syncUnpublishedChanges).toHaveBeenCalled()
  })
})
