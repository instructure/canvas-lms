define([
  'react',
  'react-addons-test-utils',
  'jsx/account_course_user_search/NewUserModal'
], (React, TestUtils, NewUserModal) => {

  QUnit.module('Account Course User Search NewUserModal View');

  const props = {
    contentLabel: 'label',
    userList: {
      errors: {}
    }
  };

  test('onChange', () => {

    const component = TestUtils.renderIntoDocument(<NewUserModal {...props} />);

    component.onChange('name', 'Test Name');
    equal(component.state.data.name, 'Test Name', 'name property gets set when needed');
    equal(component.state.data.sortable_name, 'Name, Test', 'sortable_name property gets set when needed');
    equal(component.state.data.short_name, 'Test Name', 'short name gets set properly');

    ok(!component.state.data.email, 'there is no email set prior to on change call');
    component.onChange('email', 'test@example.com');
    equal(component.state.data.email, 'test@example.com', 'non-name properties get set');
  });

  test('onSubmit', () => {
    const handlers = {
      handleAddNewUserFormErrors: sinon.spy(),
      handleAddNewUser: sinon.spy()
    };
    const component = TestUtils.renderIntoDocument(<NewUserModal handlers={handlers} {...props} />);
    component.onSubmit();
    const expectedErrors = {
      name: "Full name is required",
      email: "Email is required"
    };

    component.onChange('name', 'Test Name');
    component.onChange('email', 'test@example.com');
    component.onSubmit();
    const expectedParams = {
      user: {
        name: "Test Name",
        short_name: "Test Name",
        sortable_name: "Name, Test"
      },
      pseudonym: {
        unique_id: "test@example.com",
        send_confirmation: true
      }
    };

    ok(handlers.handleAddNewUserFormErrors.calledOnce, 'handleAddNewUserFormErrors was called once');
    ok(handlers.handleAddNewUserFormErrors.calledWith(expectedErrors), 'errors were set properly');

    ok(handlers.handleAddNewUser.calledOnce, 'handleAddNewUser was called once');
    ok(handlers.handleAddNewUser.calledWith(expectedParams), 'handleAddNewUser was called with the proper params');

  });
});