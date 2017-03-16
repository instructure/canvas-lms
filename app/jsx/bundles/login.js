import $ from 'jquery'
import LoginFormSwitcher from 'jsx/login/LoginFormSwitcher'
import 'login'

const switcher = new LoginFormSwitcher(
    $('#login_form'),
    $('#forgot_password_form')
  )

$('.forgot_password_link').click((event) => {
  event.preventDefault()
  return switcher.switchToForgotPassword()
})

$('.login_link').click((event) => {
  event.preventDefault()
  return switcher.switchToLogin()
})
