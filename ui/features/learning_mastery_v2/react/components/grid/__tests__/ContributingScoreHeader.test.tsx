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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ContributingScoreHeader, ContributingScoreHeaderProps} from '../ContributingScoreHeader'
import {ContributingScoreAlignment} from '@canvas/outcomes/react/hooks/useContributingScores'
import {SortOrder, SortBy} from '@canvas/outcomes/react/utils/constants'

const mockOpenWindow = vi.fn()
vi.mock('@canvas/util/globalUtils', () => ({
  openWindow: (url: string, target?: string) => mockOpenWindow(url, target),
}))

describe('ContributingScoreHeader', () => {
  const mockAlignment: ContributingScoreAlignment = {
    alignment_id: '1',
    associated_asset_id: '100',
    associated_asset_name: 'Assignment 1',
    associated_asset_type: 'assignment',
    html_url: '/courses/1/assignments/100',
  }

  const defaultProps = (): ContributingScoreHeaderProps => {
    return {
      alignment: mockAlignment,
      courseId: '1',
      sorting: {
        sortOrder: SortOrder.ASC,
        setSortOrder: vi.fn(),
        sortBy: SortBy.SortableName,
        setSortBy: vi.fn(),
        sortOutcomeId: null,
        setSortOutcomeId: vi.fn(),
        sortAlignmentId: null,
        setSortAlignmentId: vi.fn(),
      },
    }
  }

  beforeEach(() => {
    mockOpenWindow.mockClear()
  })

  it('renders the alignment name', () => {
    const {getByText} = render(<ContributingScoreHeader {...defaultProps()} />)
    expect(getByText('Assignment 1')).toBeInTheDocument()
  })

  it('renders a menu with "Open in Speedgrader" option', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const {getByText} = render(<ContributingScoreHeader {...defaultProps()} />)
    await user.click(getByText('Contributing Score Menu'))
    expect(getByText('Open in Speedgrader')).toBeInTheDocument()
  })

  it('opens speedgrader in a new tab when "Open in Speedgrader" is clicked', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const {getByText} = render(<ContributingScoreHeader {...defaultProps()} />)
    await user.click(getByText('Contributing Score Menu'))
    await user.click(getByText('Open in Speedgrader'))
    expect(mockOpenWindow).toHaveBeenCalledWith(
      '/courses/1/gradebook/speed_grader?assignment_id=100',
      '_blank',
    )
  })

  it('constructs the correct speedgrader URL with courseId and assignment_id', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props: ContributingScoreHeaderProps = {
      ...defaultProps(),
      alignment: {
        ...mockAlignment,
        associated_asset_id: '250',
      },
      courseId: '42',
    }
    const {getByText} = render(<ContributingScoreHeader {...props} />)
    await user.click(getByText('Contributing Score Menu'))
    await user.click(getByText('Open in Speedgrader'))
    expect(mockOpenWindow).toHaveBeenCalledWith(
      '/courses/42/gradebook/speed_grader?assignment_id=250',
      '_blank',
    )
  })

  it('renders sorting options', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const {getByText} = render(<ContributingScoreHeader {...defaultProps()} />)
    await user.click(getByText('Contributing Score Menu'))
    expect(getByText('Sort')).toBeInTheDocument()
    expect(getByText('Ascending scores')).toBeInTheDocument()
    expect(getByText('Descending scores')).toBeInTheDocument()
  })

  it('calls setSortBy and setSortAlignmentId when Ascending is clicked', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = defaultProps()
    const {getByText} = render(<ContributingScoreHeader {...props} />)
    await user.click(getByText('Contributing Score Menu'))
    await user.click(getByText('Ascending scores'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.ContributingScore)
    expect(props.sorting.setSortAlignmentId).toHaveBeenCalledWith('1')
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.ASC)
  })

  it('calls setSortBy and setSortAlignmentId when Descending is clicked', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = defaultProps()
    const {getByText} = render(<ContributingScoreHeader {...props} />)
    await user.click(getByText('Contributing Score Menu'))
    await user.click(getByText('Descending scores'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.ContributingScore)
    expect(props.sorting.setSortAlignmentId).toHaveBeenCalledWith('1')
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.DESC)
  })

  it('shows selected state when sorting by this alignment in ascending order', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = defaultProps()
    props.sorting.sortBy = SortBy.ContributingScore
    props.sorting.sortAlignmentId = '1'
    props.sorting.sortOrder = SortOrder.ASC
    const {getByText} = render(<ContributingScoreHeader {...props} />)
    await user.click(getByText('Contributing Score Menu'))
    const ascendingItem = getByText('Ascending scores').closest('[role="menuitemradio"]')
    expect(ascendingItem).toHaveAttribute('aria-checked', 'true')
  })

  it('shows selected state when sorting by this alignment in descending order', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = defaultProps()
    props.sorting.sortBy = SortBy.ContributingScore
    props.sorting.sortAlignmentId = '1'
    props.sorting.sortOrder = SortOrder.DESC
    const {getByText} = render(<ContributingScoreHeader {...props} />)
    await user.click(getByText('Contributing Score Menu'))
    const descendingItem = getByText('Descending scores').closest('[role="menuitemradio"]')
    expect(descendingItem).toHaveAttribute('aria-checked', 'true')
  })
})
