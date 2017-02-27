require [
  'jquery'
  'jsx/login/LoginFormSwitcher'
  'login'
], ($, LoginFormSwitcher) ->

  switcher = new LoginFormSwitcher(
    $("#login_form")
    $("#forgot_password_form")
  )

  $(".forgot_password_link").click (event) ->
    event.preventDefault()
    switcher.switchToForgotPassword()

  $(".login_link").click (event) ->
    event.preventDefault()
    switcher.switchToLogin()
