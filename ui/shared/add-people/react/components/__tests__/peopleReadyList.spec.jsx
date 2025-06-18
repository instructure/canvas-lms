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
import PeopleReadyList from '../people_ready_list'

const props = {
  nameList: [
    {
      address: 'addr1',
      user_id: 1,
      user_name: 'User One',
      account_id: 1,
      account_name: 'School of Rock',
      login_id: 'user1',
    },
    {
      address: 'foobar',
      user_id: 23,
      user_name: 'Foo Bar',
      account_id: 2,
      account_name: 'Site Admin',
      email: 'foo@bar.com',
      login_id: 'foobar',
      sis_user_id: 'sisid1',
    },
    {
      name: 'Xy Zzy',
      email: 'zyzzy@here.com',
      user_id: 41,
      user_name: 'Xy Zzy',
      address: 'zyzzy@here.com',
    },
  ],
  defaultInstitutionName: 'School of Hard Knocks',
}

describe('PeopleReadyList', () => {
  test('renders the component', () => {
    const wrapper = render(<PeopleReadyList {...props} />)
    expect(wrapper.getByTestId('people_ready_list')).toBeInTheDocument()
  })

  test('sets the correct values', () => {
    const wrapper = render(<PeopleReadyList {...props} />)
    const peopleReadyList = wrapper.container.querySelector('.addpeople__peoplereadylist')

    const cols = peopleReadyList.querySelectorAll('thead th')
    expect(cols).toHaveLength(5) // 5 columns

    const rows = peopleReadyList.querySelectorAll('tbody tr')
    expect(rows).toHaveLength(3) // 3 rows

    const inst0 = rows[0].lastChild.textContent
    expect(inst0).toEqual(props.nameList[0].account_name) // first user has correct institution

    const inst2 = rows[2].lastChild.textContent
    expect(inst2).toEqual(props.defaultInstitutionName) // last user has default institution name

    const sisid = rows[1].children[3].textContent
    expect(sisid).toEqual(props.nameList[1].sis_user_id) // 'middle user has sis id displayed'
  })

  test('shows no users message when no users', () => {
    const wrapper = render(<PeopleReadyList nameList={[]} />)
    const peopleReadyList = wrapper.container.querySelector('.addpeople__peoplereadylist')

    const tbls = peopleReadyList.querySelector('table')
    expect(tbls).toBeFalsy()

    expect(wrapper.getByText('No users were selected to add to the course')).toBeInTheDocument()
  })

  test('hides SIS ID column if not permitted', () => {
    const wrapper = render(<PeopleReadyList {...props} canReadSIS={true} />)
    let peopleReadyList = wrapper.container.querySelector('.addpeople__peoplereadylist')

    let cols = peopleReadyList.querySelectorAll('thead th')
    expect(cols).toHaveLength(5) // incluldes SIS ID column
    expect(cols[3].textContent).toEqual('SIS ID')

    wrapper.rerender(<PeopleReadyList {...props} canReadSIS={false} />)
    peopleReadyList = wrapper.container.querySelector('.addpeople__peoplereadylist')

    cols = peopleReadyList.querySelectorAll('thead th')
    expect(cols).toHaveLength(4) // does not inclulde SIS ID column
  })
})
