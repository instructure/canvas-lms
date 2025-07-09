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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import ModuleItemListSmart, {ModuleItemListSmartProps} from '../ModuleItemListSmart'
import type {ModuleItem} from '../../utils/types'
import {PAGE_SIZE, MODULE_ITEMS} from '../../utils/constants'

const generateItems = (count: number): ModuleItem[] =>
  Array.from({length: count}, (_, i) => ({
    _id: `mod-item-${i}`,
    id: `item-${i}`,
    url: `/modules/items/${i}`,
    indent: 0,
    position: i + 1,
    title: `Content ${i}`,
    content: {
      __typename: 'Assignment',
      id: `content-${i}`,
      title: `Content ${i}`,
    },
    masterCourseRestrictions: {
      all: false,
      availabilityDates: false,
      content: false,
      dueDates: false,
      lockDates: false,
      points: false,
      settings: false,
    },
  }))

const renderList = ({moduleItems}: {moduleItems: ModuleItem[]}) => (
  <ul data-testid="item-list">
    {moduleItems.map(item => (
      <li key={item.id}>{item.content?.title}</li>
    ))}
  </ul>
)

const defaultProps = (): Omit<ModuleItemListSmartProps, 'renderList'> => ({
  moduleId: 'mod123',
  isExpanded: true,
  view: 'teacher',
})

const renderWithClient = (
  ui: React.ReactElement,
  itemCount: number,
  cursor: string | null = null,
) => {
  const client = new QueryClient()

  client.setQueryData([MODULE_ITEMS, 'mod123', cursor], {
    moduleItems: generateItems(PAGE_SIZE),
  })

  const modulePage = {
    pageInfo: {
      hasNextPage: false,
      endCursor: null,
    },
    modules: [
      {
        _id: 'mod123',
        moduleItemsTotalCount: itemCount,
      },
    ],
    getModuleItemsTotalCount: (moduleId: string) => (moduleId === 'mod123' ? itemCount : 0),
    isFetching: false,
  }

  client.setQueryData(['modules', 'course123'], {
    pages: [modulePage],
    pageParams: [null],
    getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
    isFetching: false,
  })

  return render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>)
}

describe('ModuleItemListSmart', () => {
  // TODO: finish writing test for
  // renders paginated items and shows pagination UI when needed
  // shows loading spinner when data is loading
  // navigates to the next page and updates visible items
  it('renders all items when pagination is not needed', () => {
    const nonPaginatedCount = PAGE_SIZE
    renderWithClient(
      <ModuleItemListSmart {...defaultProps()} renderList={renderList} />,
      nonPaginatedCount,
    )
    const list = screen.getByTestId('item-list')
    expect(list.children).toHaveLength(PAGE_SIZE)
    expect(screen.queryByText(/Showing \d+-\d+ of \d+/)).not.toBeInTheDocument()
  })

  it('renders error fallback if renderList throws', async () => {
    const BadList: React.FC<{moduleItems: ModuleItem[]}> = () => {
      throw new Error('render failure')
    }
    const renderListThatThrows = ({moduleItems}: {moduleItems: ModuleItem[]}) => {
      return <BadList moduleItems={moduleItems} />
    }
    renderWithClient(
      <ModuleItemListSmart {...defaultProps()} renderList={renderListThatThrows} />,
      PAGE_SIZE,
    )
    const alertText = await screen.findByText('An unexpected error occurred.')
    expect(alertText).toBeInTheDocument()
  })
})
