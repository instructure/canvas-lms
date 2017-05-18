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

define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/missing_people_section',
], (React, ReactDOM, TestUtils, MissingPeopleSection) => {
  QUnit.module('MissingPeopleSection')

  const missingLogins = {
    addr1: {address: 'addr1', type: 'unique_id', createNew: false, newUserInfo: undefined},
    addr2: {address: 'addr2', type: 'unique_id', createNew: true, newUserInfo: {name: 'the name2', email: 'email2'}}
  }
  const missingEmails = {
    addr1: {address: 'addr1', type: 'email', createNew: true, newUserInfo: {name: 'Searched Name1', email: 'addr1'}}
  }
  const noop = function () {};
  const inviteUsersURL = '/courses/#/invite_users';

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')
    ok(missingPeopleSection)
  });

  test('renders the table', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missingLogins}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

    const headings = missingPeopleSection.querySelectorAll('thead tr th');
    equal(headings.length, 4, 'four column headings');
    const rows = missingPeopleSection.querySelectorAll('tbody tr');
    const createUserBtn = rows[0].querySelectorAll('td')[1].querySelector('button')
    equal(createUserBtn.innerHTML, 'Click to add a name', 'create new user button');
    const nameInput = rows[1].querySelector('input[type="text"]');
    ok(nameInput, 'name input');
    const emailInput = rows[1].querySelector('input[type="email"]');
    ok(emailInput, 'email input');
  });
  test('cannot create users because we don\'t have the URL', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={undefined}
        missing={missingLogins}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

    const createUserBtn = missingPeopleSection.querySelector('button');
    equal(createUserBtn, null, 'create new user button');
  })
  test('renders real names with email addresses', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="cc_path"
        inviteUsersURL={inviteUsersURL}
        missing={missingEmails}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

    const rows = missingPeopleSection.querySelectorAll('tbody tr');
    equal(rows.length, 1, 'two rows')
    const nameInput = rows[0].querySelector('input[type="text"]');
    equal(nameInput.value, 'Searched Name1', 'name input');
  });
})
