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
import ReactDOM from 'react-dom'
import {shallow, mount} from 'enzyme'
import PeopleReadyList from '../people_ready_list'

const props = {
  nameList: [
    {
      address: 'addr1',
      user_id: 1,
      user_name: 'User One',
      account_id: 1,
      account_name: 'School of Rock',
      login_id: 'user1'
    },
    {
      address: 'foobar',
      user_id: 23,
      user_name: 'Foo Bar',
      account_id: 2,
      account_name: 'Site Admin',
      email: 'foo@bar.com',
      login_id: 'foobar',
      sis_user_id: 'sisid1'
    },
    {
      name: 'Xy Zzy',
      email: 'zyzzy@here.com',
      user_id: 41,
      user_name: 'Xy Zzy',
      address: 'zyzzy@here.com'
    }
  ],
  defaultInstitutionName: 'School of Hard Knocks'
}

describe('PeopleReadyList', () => {

  test('renders the component', () => {
    const wrapper = shallow(<PeopleReadyList {...props} />)
    expect(wrapper.exists()).toBeTruthy()
  })

  test('sets the correct values', () => {
    const wrapper = shallow(<PeopleReadyList {...props} />)
    const peopleReadyList = wrapper.find('.addpeople__peoplereadylist')

    const cols = peopleReadyList.find('thead th')
    expect(cols).toHaveLength(5) // 5 columns

    const rows = peopleReadyList.find('tbody tr')
    expect(rows).toHaveLength(3) // 3 rows

    const inst0 = rows.first().children().last().text()
    expect(inst0).toEqual(props.nameList[0].account_name) // first user has correct institution

    const inst2 = rows.at(2).children().last().text()
    expect(inst2).toEqual(props.defaultInstitutionName) // last user has default institution name

    const sisid = rows.at(1).children().at(3).text()
    expect(sisid).toEqual(props.nameList[1].sis_user_id) // 'middle user has sis id displayed'
  })

  test('shows no users message when no users', () => {
    const wrapper = shallow(<PeopleReadyList nameList={[]} />)
    const peopleReadyList = wrapper.find('.addpeople__peoplereadylist')

    const tbls = peopleReadyList.find('table')
    expect(tbls.exists()).toBeFalsy()

    expect(peopleReadyList.find('Alert').prop('children')).toEqual('No users were selected to add to the course')
  })

  test('hides SIS ID column if not permitted', () => {
    let wrapper = shallow(<PeopleReadyList {...props} canReadSIS />)
    let peopleReadyList = wrapper.find('.addpeople__peoplereadylist')

    let cols = peopleReadyList.find('thead th')
    expect(cols.length).toEqual(5) // incluldes SIS ID column
    expect(cols.at(3).text()).toEqual('SIS ID')

    wrapper = shallow(<PeopleReadyList {...props} canReadSIS={false} />)
    peopleReadyList = wrapper.find('.addpeople__peoplereadylist')

    cols = peopleReadyList.find('thead th')
    expect(cols).toHaveLength(4) // does not inclulde SIS ID column
  })
})
