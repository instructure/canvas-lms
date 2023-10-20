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
import {mount, shallow} from 'enzyme'
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
    const wrapper = shallow(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
      />
    )
    expect(wrapper.find('.namelist').exists()).toBeTruthy()
  })

  test('renders the table', () => {
    const wrapper = mount(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
      />
    )
    const missingPeopleSection = wrapper.find('.namelist')

    const headings = missingPeopleSection.find('thead tr th[scope="col"]')
    expect(headings).toHaveLength(4) // four column headings
    const firstRow = missingPeopleSection.find('tbody tr').at(0)
    expect(firstRow.find('button').text()).toEqual('Click to add a name')

    expect(missingPeopleSection.find('input[type="text"]')).toHaveLength(1) // name input
    expect(missingPeopleSection.find('input[type="email"]')).toHaveLength(1) // email input
  })

  test("cannot create users because we don't have the URL", () => {
    const wrapper = mount(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={undefined}
        missing={missingLogins}
        onChange={noop}
      />
    )
    const missingPeopleSection = wrapper.find('.namelist')
    expect(missingPeopleSection.find('button')).toHaveLength(0) // create new user button
  })

  test('renders real names with email addresses', () => {
    const wrapper = mount(
      <MissingPeopleSection
        searchType="cc_path"
        inviteUsersURL={inviteUsersURL}
        missing={missingEmails}
        onChange={noop}
      />
    )
    const missingPeopleSection = wrapper.find('.namelist')

    const rows = missingPeopleSection.find('tbody tr')
    expect(rows).toHaveLength(1)
    expect(rows.find('input[type="text"]').prop('value')).toEqual('Searched Name1') // name input
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
      />
    )
    expect(container.querySelector('input[type="checkbox"][value="addr1"]').checked).toBe(false)

    const clickToAddNameLink = container.querySelector('button[data-address="addr1"]')
    fireEvent.click(clickToAddNameLink)

    waitFor(() =>
      expect(container.querySelector('input[type="checkbox"][value="addr1"]').checked).toBe(true)
    )
  })
})
