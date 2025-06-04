/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, waitFor} from '@testing-library/react'
import AllCoursesDialog from '../AllCoursesDialog'
import {fireEvent} from '@testing-library/dom'

const props = {
  embeddedLink: '',
  onClose: () => {},
  isOpen: true,
}

describe('AllCoursesDialog', () => {
  it('renders the modal and starts loading', () => {
    const {getByTestId} = render(<AllCoursesDialog {...props} />)

    expect(getByTestId('all-courses-dialog')).toBeInTheDocument()
    expect(getByTestId('all-courses-loading')).toBeInTheDocument()
  })

  it('loads iframe with source url', async () => {
    const link = 'https://example.com/'
    const {getByTestId, queryByTestId} = render(<AllCoursesDialog {...props} embeddedLink={link} />)

    const iframe = getByTestId('all-courses-iframe') as HTMLIFrameElement
    expect(iframe.src).toBe(link)

    // manually trigger load event
    fireEvent.load(iframe)

    await waitFor(() => {
      expect(queryByTestId('all-courses-loading')).toBeNull()
      // we aren't loading any actual content, so expect the iframe to be default size
      expect(getByTestId('all-courses-iframe')).toHaveStyle({width: '100%', height: '300px'})
    })
  })
})
