define([
  'react',
  'jsx/account_course_user_search/UsersListRow'
], (React, UsersListRow) => {
  const TestUtils = React.addons.TestUtils;

  module('Account Course User Search UsersListRow View');

  const user = {
    avatar_url: 'http://someurl'
  };

  const handlers = {
    handleOpenEditUserDialog () {},
    handleSubmitEditUserForm() {},
    handleCloseEditUserDialog() {}
  };

  let permissions = {
    can_masquerade: true,
    can_message_users: true,
    can_edit_users: true
  };
  const timezones = {};

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

});
