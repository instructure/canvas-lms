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
import {render} from '@testing-library/react'
import PeopleValidationIssues from '../people_validation_issues'

describe('PeopleValidationIssues', () => {
  const duplicates = {
    addr1: {
      address: 'addr1',
      selectedUserId: -1,
      skip: false,
      createNew: false,
      newUserInfo: undefined,
      userList: [
        {
          address: 'addr1',
          user_id: 1,
          user_name: 'Addr1 User1',
          account_id: 1,
          account_name: 'School of Rock',
          email: 'addr1@foo.com',
          login_id: 'addr1',
        },
        {
          address: 'addr1',
          user_id: 2,
          user_name: 'Addr1 User2',
          account_id: 1,
          account_name: 'School of Rock',
          email: 'addr1@foo.com',
          login_id: 'addr1',
        },
      ],
    },
    addr2: {
      address: 'addr2',
      selectedUserId: -1,
      skip: false,
      createNew: false,
      newUserInfo: undefined,
      userList: [
        {
          address: 'addr2',
          user_id: 3,
          user_name: 'addr2User',
          account_id: 1,
          account_name: 'School of Rock',
          email: 'addr2@foo.com',
          login_id: 'addr2',
        },
        {
          address: 'addr2',
          user_id: 4,
          user_name: 'addr2User',
          account_id: 1,
          account_name: 'School of Rock',
          email: 'addr2@foo.com',
          login_id: 'addr1',
        },
      ],
    },
  }

  const missing = {
    addr3: {address: 'addr3', type: 'unique_id', createNew: false, newUserInfo: undefined},
    addr4: {
      address: 'addr4',
      type: 'unique_id',
      createNew: true,
      newUserInfo: {name: 'the name2', email: 'email2'},
    },
  }

  const inviteUsersURL = '/courses/#/invite_users'
  const noop = () => {}

  it('renders the component', () => {
    const {container} = render(
      <PeopleValidationIssues
        duplicates={duplicates}
        missing={missing}
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        onChangeDuplicate={noop}
        onChangeMissing={noop}
        fieldsRefAndError={{}}
      />,
    )

    // Check if the main panel rendered
    expect(container.querySelector('.addpeople__peoplevalidationissues')).toBeInTheDocument()

    // Check if sections rendered
    expect(container.querySelector('.peopleValidationissues__duplicates')).toBeInTheDocument()
    expect(container.querySelector('.peoplevalidationissues__missing')).toBeInTheDocument()

    // Check number of duplicate sets
    const dupeSets = container.querySelectorAll('.peopleValidationissues__duplicates .namelist')
    expect(dupeSets).toHaveLength(2)
  })
})
