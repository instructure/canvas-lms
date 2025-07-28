/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import MissingPeopleSection from '../missing_people_section'
import {fireEvent, render, waitFor} from '@testing-library/react'

describe('MissingPeopleSection', () => {
  const missingLogins = {
    addr1: {address: 'addr1', type: 'unique_id', createNew: false, newUserInfo: undefined},
    addr2: {
      address: 'addr2',
      type: 'unique_id',
      createNew: true,
      newUserInfo: {name: 'the name2', email: 'email2'},
    },
  }
  const missingEmails = {
    addr1: {
      address: 'addr1',
      type: 'email',
      createNew: true,
      newUserInfo: {name: 'Searched Name1', email: 'addr1'},
    },
  }
  const noop = function () {}
  const inviteUsersURL = '/courses/#/invite_users'

  test('renders the component', () => {
    const wrapper = render(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
        fieldsRefAndError={{}}
      />,
    )
    expect(wrapper.getByTestId('addpeople__missing-namelist')).toBeInTheDocument()
  })

  test('renders the table', () => {
    const wrapper = render(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
        fieldsRefAndError={{}}
      />,
    )
    const missingPeopleSection = wrapper.container.querySelector('.namelist')

    const headings = missingPeopleSection.querySelectorAll('thead tr th[scope="col"]')
    expect(headings).toHaveLength(4) // four column headings
    const firstRow = missingPeopleSection.querySelectorAll('tbody tr')[0]
    expect(firstRow.querySelector('button').textContent).toEqual('Click to add a name')

    expect(missingPeopleSection.querySelectorAll('input[type="text"]')).toHaveLength(1) // name input
    expect(missingPeopleSection.querySelectorAll('input[type="email"]')).toHaveLength(1) // email input
  })

  test("cannot create users because we don't have the URL", () => {
    const wrapper = render(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={undefined}
        missing={missingLogins}
        onChange={noop}
        fieldsRefAndError={{}}
      />,
    )
    const missingPeopleSection = wrapper.container.querySelector('.namelist')
    expect(missingPeopleSection.querySelectorAll('button')).toHaveLength(0) // create new user button
  })

  test('renders real names with email addresses', () => {
    const wrapper = render(
      <MissingPeopleSection
        searchType="cc_path"
        inviteUsersURL={inviteUsersURL}
        missing={missingEmails}
        onChange={noop}
        fieldsRefAndError={{}}
      />,
    )
    const missingPeopleSection = wrapper.container.querySelector('.namelist')

    const rows = missingPeopleSection.querySelectorAll('tbody tr')
    expect(rows).toHaveLength(1)
    expect(wrapper.getByDisplayValue('Searched Name1')).toBeInTheDocument() // name input
  })

  it('selects the checkbox when the "Click to add a name" link is clicked', () => {
    const missing = {
      addr1: {
        address: 'addr1',
        type: 'email',
        createNew: false,
        newUserInfo: {name: 'Searched Name1', email: 'addr1'},
      },
    }

    const {container} = render(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missing}
        onChange={noop}
        fieldsRefAndError={{}}
      />,
    )
    expect(container.querySelector('input[type="checkbox"][value="addr1"]').checked).toBe(false)

    const clickToAddNameLink = container.querySelector('button[data-address="addr1"]')
    fireEvent.click(clickToAddNameLink)

    waitFor(() =>
      expect(container.querySelector('input[type="checkbox"][value="addr1"]').checked).toBe(true),
    )
  })
})
