define([], () => {
  class LoginFormSwitcher {
    constructor($loginForm, $forgotPasswordForm) {
      this.$loginForm = $loginForm;
      this.$forgotPasswordForm = $forgotPasswordForm;
    }

    switchToLogin() {
      this.$forgotPasswordForm.hide();
      this.$loginForm.show();
      this.$loginForm.find("input:visible:first").focus();
    }

    switchToForgotPassword() {
      this.$loginForm.hide();
      this.$forgotPasswordForm.show();
      this.$forgotPasswordForm.find("input:visible:first").focus();
    }
  }

  return LoginFormSwitcher;
});
