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

import {cloneDeep} from 'lodash'
import React from 'react'
import TestUtils from 'react-dom/test-utils'
import DuplicateSection from '@canvas/add-people/react/components/duplicate_section'

QUnit.module('DuplicateSection')

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
const noop = function () {}
const inviteUsersURL = '/couses/#/invite_users'

test('renders the component', () => {
  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={duplicates}
      inviteUsersURL={inviteUsersURL}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')
  ok(duplicateSection)
})

test('renders the table', () => {
  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={duplicates}
      inviteUsersURL={inviteUsersURL}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

  const rows = duplicateSection.querySelectorAll('tr')
  equal(rows.length, 5, 'five rows')
  const headings = rows[0].querySelectorAll('th')
  equal(headings.length, 6, 'six column headings')
  const createNewRow = duplicateSection.querySelector('tr[data-testid="create-new"]')
  ok(createNewRow, 'create new row exists')

  const createUserBtn = createNewRow.querySelector('button')
  ok(createUserBtn)
  equal(createUserBtn.innerText, 'Create a new user for "addr1"')

  const skipUserRow = duplicateSection.querySelector('tr[data-testid="skip-addr"]')
  ok(skipUserRow, 'skip user row exists')

  const skipUserBtn = skipUserRow.querySelector('button')
  equal(skipUserBtn.innerText, 'Don’t add this user for now.', 'skip user button')
})
test('select a user', () => {
  const dupes = cloneDeep(duplicates)
  dupes.selectedUserId = 2
  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={dupes}
      inviteUsersURL={inviteUsersURL}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

  const rows = duplicateSection.querySelectorAll('tr')
  const radio1 = rows[1].querySelector('input[type="radio"]')
  const radio2 = rows[2].querySelector('input[type="radio"]')
  equal(radio1.checked, false, 'user 1 not selected')
  equal(radio2.checked, true, 'user 2 selected')
})
test('create a user', () => {
  const dupes = cloneDeep(duplicates)
  dupes.createNew = true
  dupes.newUserInfo = {name: 'bob', email: 'bob@em.ail'}
  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={dupes}
      inviteUsersURL={inviteUsersURL}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

  const rows = duplicateSection.querySelectorAll('tr')
  const nameInput = rows[3].querySelector('input[type="text"]')
  ok(nameInput, 'name input exists')
  equal(nameInput.value, 'bob', 'name has correct value')
  const emailInput = rows[3].querySelector('input[type="email"]')
  ok(emailInput, 'email input') // 'email input exists'
  equal(emailInput.value, 'bob@em.ail', 'email has correct value')
})
test('skip a set of dupes', () => {
  const dupes = cloneDeep(duplicates)
  dupes.skip = true
  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={dupes}
      inviteUsersURL={inviteUsersURL}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

  const rows = duplicateSection.querySelectorAll('tr')
  const skipUserRadioBtn = rows[4].querySelector('input[type="radio"]')
  equal(skipUserRadioBtn.checked, true, 'duplicate set skipped')
})
test('cannot create a user', () => {
  const dupes = cloneDeep(duplicates)

  const component = TestUtils.renderIntoDocument(
    <DuplicateSection
      duplicates={dupes}
      inviteUsersURL={undefined}
      onSelectDuplicate={noop}
      onNewForDuplicate={noop}
      onSkipDuplicate={noop}
    />
  )
  const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

  const createNewRow = duplicateSection.querySelector('tr[data-testid="create-new"]')
  equal(createNewRow, null, 'create new user row does not exist')
})
