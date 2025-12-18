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
import {cleanup, render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {StudentHeader, StudentHeaderProps} from '../StudentHeader'
import {SortOrder, SortBy, NameDisplayFormat} from '../../../utils/constants'

const makeProps = (props = {}): StudentHeaderProps => {
  return {
    sorting: {
      sortOrder: SortOrder.ASC,
      setSortOrder: vi.fn(),
      sortBy: SortBy.Name,
      setSortBy: vi.fn(),
      sortOutcomeId: null,
      setSortOutcomeId: vi.fn(),
      sortAlignmentId: null,
      setSortAlignmentId: vi.fn(),
    },
    nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
    onChangeNameDisplayFormat: vi.fn(),
    ...props,
  }
}

describe('StudentHeader', () => {
  afterEach(() => {
    cleanup()
  })

  it('renders a "Student" cell', () => {
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    expect(getByText('Students')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    await user.click(getByText('Student Options'))
    expect(getByText('Sort Order')).toBeInTheDocument()
    expect(getByText('Ascending')).toBeInTheDocument()
    expect(getByText('Descending')).toBeInTheDocument()
  })

  it('renders sorting options for student attributes', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const {getByText, queryByText} = render(<StudentHeader {...makeProps()} />)
    await user.click(getByText('Student Options'))
    expect(getByText('Sort By')).toBeInTheDocument()
    expect(getByText('Name')).toBeInTheDocument()
    expect(queryByText('Sortable Name')).not.toBeInTheDocument()
    expect(getByText('SIS ID')).toBeInTheDocument()
    expect(getByText('Integration ID')).toBeInTheDocument()
    expect(getByText('Login ID')).toBeInTheDocument()
  })

  it('calls setSortOrder when a sorting option is selected', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    await user.click(getByText('Student Options'))
    await user.click(getByText('Ascending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.ASC)
  })

  it('calls setSortOrder with descending order when "Descending" is selected', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    await user.click(getByText('Student Options'))
    await user.click(getByText('Descending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.DESC)
  })

  it('calls setSortBy when a sort by option is selected', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    const menu = getByText('Student Options')

    await user.click(menu)
    await user.click(getByText('SIS ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.SisId)

    await user.click(menu)
    await user.click(getByText('Integration ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.IntegrationId)

    await user.click(menu)
    await user.click(getByText('Login ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.LoginId)
  })

  it('calls setSortBy with Name when Name is selected and display format is FIRST_LAST', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = makeProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})
    const {getByText} = render(<StudentHeader {...props} />)
    await user.click(getByText('Student Options'))
    await user.click(getByText('Name'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.Name)
  })

  it('calls setSortBy with SortableName when Name is selected and display format is LAST_FIRST', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})
    const props = makeProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})
    const {getByText} = render(<StudentHeader {...props} />)
    await user.click(getByText('Student Options'))
    await user.click(getByText('Name'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.SortableName)
  })

  describe('Display as menu', () => {
    it('renders Display as menu group with name format options', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const {getByText} = render(<StudentHeader {...makeProps()} />)
      await user.click(getByText('Student Options'))
      expect(getByText('Display as')).toBeInTheDocument()
      expect(getByText('First, Last Name')).toBeInTheDocument()
      expect(getByText('Last, First Name')).toBeInTheDocument()
    })

    it('selects First, Last Name when nameDisplayFormat is FIRST_LAST', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      const firstLastItem = getByText('First, Last Name').closest('[role="menuitemradio"]')
      expect(firstLastItem).toHaveAttribute('aria-checked', 'true')
    })

    it('selects Last, First Name when nameDisplayFormat is LAST_FIRST', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      const lastFirstItem = getByText('Last, First Name').closest('[role="menuitemradio"]')
      expect(lastFirstItem).toHaveAttribute('aria-checked', 'true')
    })

    it('calls onChangeNameDisplayFormat with FIRST_LAST when First, Last Name is selected', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      await user.click(getByText('First, Last Name'))
      expect(props.onChangeNameDisplayFormat).toHaveBeenCalledWith(NameDisplayFormat.FIRST_LAST)
    })

    it('calls onChangeNameDisplayFormat with LAST_FIRST when Last, First Name is selected', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      await user.click(getByText('Last, First Name'))
      expect(props.onChangeNameDisplayFormat).toHaveBeenCalledWith(NameDisplayFormat.LAST_FIRST)
    })

    it('updates sortBy to SortableName when changing to LAST_FIRST format while sorting by Name', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        sorting: {
          sortOrder: SortOrder.ASC,
          setSortOrder: vi.fn(),
          sortBy: SortBy.Name,
          setSortBy: vi.fn(),
          sortOutcomeId: null,
          setSortOutcomeId: vi.fn(),
        },
      })
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      await user.click(getByText('Last, First Name'))
      expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.SortableName)
    })

    it('updates sortBy to Name when changing to FIRST_LAST format while sorting by SortableName', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({
        nameDisplayFormat: NameDisplayFormat.LAST_FIRST,
        sorting: {
          sortOrder: SortOrder.ASC,
          setSortOrder: vi.fn(),
          sortBy: SortBy.SortableName,
          setSortBy: vi.fn(),
          sortOutcomeId: null,
          setSortOutcomeId: vi.fn(),
        },
      })
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      await user.click(getByText('First, Last Name'))
      expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.Name)
    })

    it('does not update sortBy when changing display format while sorting by SIS ID', async () => {
      const user = userEvent.setup({pointerEventsCheck: 0})
      const props = makeProps({
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        sorting: {
          sortOrder: SortOrder.ASC,
          setSortOrder: vi.fn(),
          sortBy: SortBy.SisId,
          setSortBy: vi.fn(),
          sortOutcomeId: null,
          setSortOutcomeId: vi.fn(),
        },
      })
      const {getByText} = render(<StudentHeader {...props} />)
      await user.click(getByText('Student Options'))
      await user.click(getByText('Last, First Name'))
      expect(props.sorting.setSortBy).not.toHaveBeenCalled()
    })
  })
})
