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
import userEvent from '@testing-library/user-event'
import SmartSearchFilters, {ALL_SOURCES} from '../SmartSearchFilters'

const props = {
  handleCloseTray: vi.fn(),
  updateFilters: vi.fn(),
  filters: ALL_SOURCES,
}

describe('SmartSearchFilters', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders filters as checked', () => {
    const {getByText, getByTestId} = render(<SmartSearchFilters {...props} />)
    expect(getByText('Filters')).toBeInTheDocument()
    expect(getByText('Sources')).toBeInTheDocument()

    expect(getByTestId('all-sources-checkbox')).toBeChecked()
    expect(getByTestId('assignments-checkbox')).toBeChecked()
    expect(getByTestId('announcements-checkbox')).toBeChecked()
    expect(getByTestId('discussion-topics-checkbox')).toBeChecked()
    expect(getByTestId('pages-checkbox')).toBeChecked()
  })

  it('sends correct values when applying filters', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<SmartSearchFilters {...props} />)

    await user.click(getByTestId('assignments-checkbox'))
    await user.click(getByTestId('announcements-checkbox'))
    await user.click(getByTestId('apply-filters-button'))
    await waitFor(() => {
      expect(props.updateFilters).toHaveBeenCalledWith(['discussion_topics', 'pages'])
    })
  })

  it('resets filters to all being selected', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<SmartSearchFilters {...props} />)

    await user.click(getByTestId('all-sources-checkbox'))
    await waitFor(() => {
      expect(getByTestId('assignments-checkbox')).not.toBeChecked()
      expect(getByTestId('announcements-checkbox')).not.toBeChecked()
      expect(getByTestId('discussion-topics-checkbox')).not.toBeChecked()
      expect(getByTestId('pages-checkbox')).not.toBeChecked()
    })
    await user.click(getByTestId('reset-filters-button'))
    await waitFor(() => {
      expect(getByTestId('all-sources-checkbox')).toBeChecked()
      expect(getByTestId('assignments-checkbox')).toBeChecked()
      expect(getByTestId('announcements-checkbox')).toBeChecked()
      expect(getByTestId('discussion-topics-checkbox')).toBeChecked()
      expect(getByTestId('pages-checkbox')).toBeChecked()
      expect(props.updateFilters).not.toHaveBeenCalled()
    })
  })
})
