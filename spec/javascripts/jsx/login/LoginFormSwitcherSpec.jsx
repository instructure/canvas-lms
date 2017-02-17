define([
  'jsx/login/LoginFormSwitcher'
], (LoginFormSwitcher) => {

  let loginFormInput;
  let loginForm;
  let forgotPasswordFormInput;
  let forgotPasswordForm;
  let switcher;

  QUnit.module("LoginFormSwitcher", {
    setup() {
      loginFormInput = {
        focus: sinon.stub()
      };
      loginForm = {
        hide: sinon.stub(),
        show: sinon.stub(),
        find: () => loginFormInput
      };
      forgotPasswordFormInput = {
        focus: sinon.stub()
      };
      forgotPasswordForm = {
        hide: sinon.stub(),
        show: sinon.stub(),
        find: () => forgotPasswordFormInput
      };
      switcher = new LoginFormSwitcher(
        loginForm,
        forgotPasswordForm
      );
    }
  });

  test("switches to login", () => {
    switcher.switchToLogin();
    ok(forgotPasswordForm.hide.called);
    ok(loginForm.show.called);
    ok(loginFormInput.focus.called);
  });

  test("switches to forgot password", () => {
    switcher.switchToForgotPassword();
    ok(loginForm.hide.called);
    ok(forgotPasswordForm.show.called);
    ok(forgotPasswordFormInput.focus.called);
  });
});
