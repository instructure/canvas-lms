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

define(
  ['react', 'react-dom', 'jsx/add_people/components/people_ready_list'],
  (React, ReactDOM, PeopleReadyList) => {
    let domNode

    function renderComponent(props) {
      domNode = domNode || document.createElement('div')
      ReactDOM.render(<PeopleReadyList {...props} />, domNode)
    }

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

    QUnit.module('PeopleReadyList')

    test('renders the component', () => {
      renderComponent(props)
      const component = domNode.querySelectorAll('.addpeople__peoplereadylist')
      ok(component)
    })
    test('sets the correct values', () => {
      renderComponent(props)
      const peopleReadyList = domNode.querySelector('.addpeople__peoplereadylist')

      const cols = peopleReadyList.querySelectorAll('thead th')
      equal(cols.length, 5, '5 columns')

      const rows = peopleReadyList.querySelectorAll('tbody tr')
      equal(rows.length, 3, '3 rows')

      const inst0 = rows[0].querySelectorAll('td')[4].innerHTML
      equal(inst0, props.nameList[0].account_name, 'first user has correct institution')

      const inst2 = rows[2].querySelectorAll('td')[4].innerHTML
      equal(inst2, props.defaultInstitutionName, 'last user has default institution name')

      const sisid = rows[1].querySelectorAll('td')[3].innerHTML
      equal(sisid, props.nameList[1].sis_user_id, 'middle user has sis id displayed')
    })
    test('shows no users message when no users', () => {
      renderComponent({nameList: []})
      const peopleReadyList = domNode.querySelector('.addpeople__peoplereadylist')

      const tbls = peopleReadyList.querySelector('table')
      equal(tbls, null, 'no tables')

      equal(peopleReadyList.innerText.trim(), 'No users were selected to add to the course')
    })
    test('hides SIS ID column if not permitted', () => {
      const p = Object.assign({}, props, {canReadSIS: true})
      renderComponent(p)
      let peopleReadyList = domNode.querySelector('.addpeople__peoplereadylist')
      let cols = peopleReadyList.querySelectorAll('thead th')
      equal(cols.length, 5, 'incluldes SIS ID column')

      p.canReadSIS = false
      renderComponent(p)
      peopleReadyList = domNode.querySelector('.addpeople__peoplereadylist')
      cols = peopleReadyList.querySelectorAll('thead th')
      equal(cols.length, 4, 'does not inclulde SIS ID column')
    })
  }
)
