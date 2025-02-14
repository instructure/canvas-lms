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
import SectionList from '../SectionList'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

describe('SectionList', () => {
  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: 'path/to/profile'}
  const sectionList = [
    {name: 'First Section', id: 1, position: 1, category_url: '/path/to/first'},
    {name: 'Second Section', id: 2, position: 2, category_url: 'path/to/second'},
  ]

  const defaultProps = {
    portfolio,
    isOwner: true,
    onConfirm: jest.fn(),
    sections: sectionList,
  }

  it('fetches and renders a list of sections', async () => {
    const {findByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    expect(await findByText('First Section')).toBeInTheDocument()
    expect(await findByText('Second Section')).toBeInTheDocument()
  })

  it('renders the user profile', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    const profileButton = await findByTestId('user-profile')
    expect(profileButton).toBeInTheDocument()
    expect(profileButton).toHaveAttribute('href', 'path/to/profile')
  })

  it('does not render menu if user is not the owner', async () => {
    const {queryByTestId, findByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} isOwner={false} />
      </MockedQueryClientProvider>,
    )
    expect(await findByText('First Section')).toBeInTheDocument()
    expect(queryByTestId('1-menu')).not.toBeInTheDocument()
  })

  it('opens add modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    const addSection = await findByTestId('add-section-button')
    addSection.click()
    expect(await findByTestId('add-section-modal')).toBeInTheDocument()
  })

  it('open rename modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('1-menu')
    menuButton.click()
    const renameOption = await findByTestId('rename-menu-option')
    renameOption.click()
    expect(await findByTestId('rename-section-modal')).toBeInTheDocument()
  })

  it('opens delete modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('2-menu')
    menuButton.click()
    const deleteOption = await findByTestId('delete-menu-option')
    deleteOption.click()
    expect(await findByTestId('delete-section-modal')).toBeInTheDocument()
  })

  it('open move modal', async () => {
    const {findByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )
    const menuButton = await findByTestId('1-menu')
    menuButton.click()
    const moveOption = await findByTestId('move-menu-option')
    moveOption.click()
    expect(await findByTestId('move-section-modal')).toBeInTheDocument()
  })

  it('does not render profile button if no link if provided', async () => {
    const {findByText, queryByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SectionList {...defaultProps} portfolio={{...portfolio, profile_url: null}} />
      </MockedQueryClientProvider>,
    )
    expect(await findByText('First Section')).toBeInTheDocument()
    const userProfileBtn = queryByText('User Profile')
    expect(userProfileBtn).toBeNull()
  })
})
