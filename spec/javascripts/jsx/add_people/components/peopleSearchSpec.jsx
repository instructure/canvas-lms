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
import TestUtils from 'react-dom/test-utils'
import PeopleSearch from '@canvas/add-people/react/components/people_search'

QUnit.module('PeopleSearch')

const searchProps = {
  roles: [
    {id: '1', label: 'Student'},
    {id: '2', label: 'TA'},
  ],
  sections: [
    {id: '1', name: 'Section 2'},
    {id: '2', name: 'Section 10'},
  ],
  section: '1',
  role: '2',
  limitPrivilege: true,
  searchType: 'unique_id',
  nameList: 'foo, bar, baz',
  canReadSIS: true,
}

test('renders the component', () => {
  const component = TestUtils.renderIntoDocument(<PeopleSearch {...searchProps} />)
  const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'addpeople__peoplesearch'
  )
  ok(peopleSearch)
})
test('sets the correct values', () => {
  const component = TestUtils.renderIntoDocument(<PeopleSearch {...searchProps} />)
  const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'addpeople__peoplesearch'
  )
  const loginRadio = peopleSearch.querySelector('input[type="radio"][value="unique_id"]')
  equal(loginRadio.checked, true, 'login id radio button is checked')
  const nameInput = peopleSearch.querySelector('textarea')
  equal(nameInput.value, searchProps.nameList, 'names are in the textarea')
  const roleSelect = peopleSearch.querySelector('#peoplesearch_select_role')
  equal(roleSelect.value, 'TA', 'correct role is selected')
  const sectionSelect = peopleSearch.querySelector('#peoplesearch_select_section')
  equal(sectionSelect.value, 'Section 2', 'correct section is selected')
  const limitPrivilegeCheckbox = peopleSearch.querySelector('#limit_privileges_to_course_section')
  equal(limitPrivilegeCheckbox.checked, true, 'limit privileges checkbox is checked')
})
test('removes search by SIS ID', () => {
  const newProps = {...searchProps, canReadSIS: false}
  const component = TestUtils.renderIntoDocument(<PeopleSearch {...newProps} />)
  const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'addpeople__peoplesearch'
  )
  const sisRadio = peopleSearch.querySelector('input[type="radio"][value="sis_user_id"]')
  equal(sisRadio, null, 'sis id radio button is not displayed')
})
test('shows hint with bad email address', () => {
  const badEmail = 'foobar@'
  const newProps = {...searchProps, searchType: 'cc_path', nameList: badEmail}
  const component = TestUtils.renderIntoDocument(<PeopleSearch {...newProps} />)
  const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'addpeople__peoplesearch'
  )
  const nameInput = peopleSearch.querySelector('textarea')
  equal(nameInput.value, badEmail, 'email is in the textarea')
  ok(peopleSearch.innerHTML.includes('It looks like you have an invalid email address: "foobar@"'))
})
