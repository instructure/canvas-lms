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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import Bridge from '../../../../../../../bridge'
import {MyImages} from '../MyImages'

jest.mock('../../../../../../../bridge')

Bridge.trayProps = {
  get: () => ({
    source: {
      initializeCollection() {},
      initializeUpload() {},
      initializeFlickr() {},
      initializeImages() {},
      initializeDocuments() {},
      initializeMedia() {}
    }
  })
}

describe('<MyImages />', () => {
  it('renders the upload modal', () => {
    render(<MyImages editor={{}} />)
    userEvent.click(screen.getByText(/add image/i))
    screen.getByRole('heading', {name: /add image/i})
    const closeButton = screen.getAllByRole('button', {name: /close/i})[0]
    userEvent.click(closeButton)
    expect(screen.queryByRole('heading', {name: /add image/i})).toBeNull()
  })
})
