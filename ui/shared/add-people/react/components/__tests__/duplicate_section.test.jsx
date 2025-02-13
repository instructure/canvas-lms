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

import {cloneDeep} from 'lodash'
import React from 'react'
import {render, screen, within} from '@testing-library/react'
import DuplicateSection from '../duplicate_section'

const duplicates = {
  address: 'addr1',
  selectedUserId: -1,
  skip: false,
  createNew: false,
  newUserInfo: undefined,
  userList: [
    {
      address: 'addr1',
      user_id: 1,
      user_name: 'addr1User',
      account_id: 1,
      account_name: 'School of Rock',
      email: 'addr1@foo.com',
      login_id: 'addr1',
    },
    {
      address: 'addr1',
      user_id: 2,
      user_name: 'addr2User',
      account_id: 1,
      account_name: 'School of Rock',
      email: 'addr2@foo.com',
      login_id: 'addr1',
    },
  ],
}

const defaultProps = {
  duplicates,
  inviteUsersURL: '/courses/#/invite_users',
  onSelectDuplicate: jest.fn(),
  onNewForDuplicate: jest.fn(),
  onSkipDuplicate: jest.fn(),
  fieldsRefAndError: {},
}

describe('DuplicateSection', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the component with user list', () => {
    render(<DuplicateSection {...defaultProps} />)
    expect(screen.getByRole('table', {hidden: true})).toBeInTheDocument()
  })

  it('renders table with correct columns and rows', () => {
    render(<DuplicateSection {...defaultProps} />)
    expect(screen.getAllByRole('columnheader', {hidden: true})).toHaveLength(6)
    expect(screen.getAllByRole('row', {hidden: true})).toHaveLength(5)
  })

  it('renders create new user button with correct text', () => {
    render(<DuplicateSection {...defaultProps} />)
    expect(
      screen.getByText((content, element) => {
        return (
          element.tagName.toLowerCase() === 'span' &&
          content.includes('Create a new user for "addr1"')
        )
      }),
    ).toBeInTheDocument()
  })

  it('renders skip user button with correct text', () => {
    render(<DuplicateSection {...defaultProps} />)
    const skipRow = screen.getByTestId('skip-addr')
    const skipButton = within(skipRow).getByRole('button')
    expect(skipButton.textContent.trim()).toBe('Don’t add this user for now.')
  })

  it('shows selected user when selectedUserId is set', () => {
    const dupes = cloneDeep(duplicates)
    dupes.selectedUserId = 2
    render(<DuplicateSection {...defaultProps} duplicates={dupes} />)

    const radioButtons = screen.getAllByRole('radio', {hidden: true})
    expect(radioButtons[1]).toBeChecked()
    expect(radioButtons[0]).not.toBeChecked()
  })

  it('shows create new user form when createNew is true', () => {
    const dupes = cloneDeep(duplicates)
    dupes.createNew = true
    dupes.newUserInfo = {name: 'bob', email: 'bob@em.ail'}
    render(<DuplicateSection {...defaultProps} duplicates={dupes} />)

    expect(screen.getByDisplayValue('bob')).toBeInTheDocument()
    expect(screen.getByDisplayValue('bob@em.ail')).toBeInTheDocument()
  })

  it('shows skip option as selected when skip is true', () => {
    const dupes = cloneDeep(duplicates)
    dupes.skip = true
    render(<DuplicateSection {...defaultProps} duplicates={dupes} />)

    const skipRadio = screen.getByRole('radio', {
      name: /click to skip addr1/i,
      hidden: true,
    })
    expect(skipRadio).toBeChecked()
  })

  it('does not show create new user option when inviteUsersURL is undefined', () => {
    render(<DuplicateSection {...defaultProps} inviteUsersURL={undefined} />)
    expect(
      screen.queryByText((content, element) => {
        return (
          element.tagName.toLowerCase() === 'span' &&
          content.includes('Create a new user for "addr1"')
        )
      }),
    ).not.toBeInTheDocument()
  })
})
