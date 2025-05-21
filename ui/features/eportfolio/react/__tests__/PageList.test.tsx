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
import {render} from '@testing-library/react'
import PageList from '../PageList'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

describe('PageList', () => {
  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: '/path/to/portfolio'}
  const section = {id: 10, name: 'Test Section', position: 1, category_url: '/path/to/section'}

  const pageList = [
    {
      json: [
        {name: 'First Page', id: 1, entry_url: '/path/to/first'},
        {name: 'Second Page', id: 2, entry_url: 'path/to/second'},
      ],
      nextPage: null,
    },
  ]

  const props = {
    isLoading: false,
    portfolio: portfolio,
    sectionId: section.id,
    sectionName: section.name,
    onUpdate: jest.fn(),
    isOwner: true,
  }

  beforeAll(() => {
    // Set up the query data in the format expected by useInfiniteQuery
    queryClient.setQueryData(['portfolioPageList', portfolio.id, section.id], {
      pages: pageList,
      pageParams: ['1'],
    })
  })

  it('fetches and renders a list of pages', async () => {
    const {findByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} />
      </MockedQueryClientProvider>,
    )
    expect(await findByText('First Page')).toBeInTheDocument()
    expect(await findByText('Second Page')).toBeInTheDocument()
  })

  it('does not render menu if user is not the owner', async () => {
    const {queryByTestId, findByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} isOwner={false} />
      </MockedQueryClientProvider>,
    )
    expect(await findByText('First Page')).toBeInTheDocument()
    expect(queryByTestId('1-menu')).not.toBeInTheDocument()
  })

  it('opens add modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} />
      </MockedQueryClientProvider>,
    )
    const addPage = await findByTestId('add-page-button')
    addPage.click()
    expect(await findByTestId('add-page-modal')).toBeInTheDocument()
  })

  it('open rename modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('1-menu')
    menuButton.click()
    const renameOption = await findByTestId('rename-menu-option')
    renameOption.click()
    expect(await findByTestId('rename-page-modal')).toBeInTheDocument()
  })

  it('opens delete modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('2-menu')
    menuButton.click()
    const deleteOption = await findByTestId('delete-menu-option')
    deleteOption.click()
    expect(await findByTestId('delete-page-modal')).toBeInTheDocument()
  })

  it('open move modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <PageList {...props} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('1-menu')
    menuButton.click()
    const moveOption = await findByTestId('move-menu-option')
    moveOption.click()
    expect(await findByTestId('move-page-modal')).toBeInTheDocument()
  })
})
