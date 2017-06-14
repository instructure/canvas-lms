/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import UsersListRow from 'jsx/account_course_user_search/UsersListRow'

QUnit.module('Account Course User Search UsersListRow View');

const user = {
  id: '1',
  name: 'foo',
  avatar_url: 'http://someurl'
};

const handlers = {
  handleOpenEditUserDialog () {},
  handleSubmitEditUserForm () {},
  handleCloseEditUserDialog () {}
};

let permissions = {
  can_masquerade: true,
  can_message_users: true,
  can_edit_users: true
};
const timezones = {timezones: ['123123123'], priority_zones: ['alsdkfjasldkfjs']};

test('renders an avatar when needed', () => {
  const withPropComponent = TestUtils.renderIntoDocument(
    <UsersListRow
      user={user}
      handlers={handlers}
      permissions={permissions}
      timezones={timezones}
    />
  );

  const avatarElement = TestUtils.findRenderedDOMComponentWithClass(withPropComponent, 'ic-avatar');
  ok(avatarElement, 'the avatarElement is found when given user.avatar_url as prop');

  const originalAvatar = user.avatar_url;
  user.avatar_url = undefined;

  const withoutPropComponent = TestUtils.renderIntoDocument(
    <UsersListRow
      user={user}
      handlers={handlers}
      permissions={permissions}
      timezones={timezones}
    />
  );

  // We use scry here so we don't get the expcetion since we are testing that
  // it doesn't exist in this case.
  const avatarElements = TestUtils.scryRenderedDOMComponentsWithClass(withoutPropComponent, 'ic-avatar');
  equal(avatarElements.length, 0, 'the avatar is not rendered');

  // Restore the state change
  user.avatar_url = originalAvatar;
});

test('renders all actions when all permissions are present', () => {
  const component = TestUtils.renderIntoDocument(
    <UsersListRow
      user={user}
      handlers={handlers}
      permissions={permissions}
      timezones={timezones}
    />
  );

  const actions = TestUtils.scryRenderedDOMComponentsWithClass(component, 'user_actions_js_test');
  equal(actions.length, 3);
});

test('renders no actions if no permissions are present', () => {
  const originalPermissions = Object.assign({}, permissions);

  permissions = {
    can_masquerade: false,
    can_message_users: false,
    can_edit_users: false
  };

  const component = TestUtils.renderIntoDocument(
    <UsersListRow
      user={user}
      handlers={handlers}
      permissions={permissions}
      timezones={timezones}
    />
  );

  const actions = TestUtils.scryRenderedDOMComponentsWithClass(component, 'user_actions_js_test');
  equal(actions.length, 0);

  permissions = originalPermissions;
});
