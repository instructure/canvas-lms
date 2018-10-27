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

import LoginFormSwitcher from 'jsx/login/LoginFormSwitcher'

let loginFormInput
let loginForm
let forgotPasswordFormInput
let forgotPasswordForm
let switcher

QUnit.module('LoginFormSwitcher', {
  setup() {
    loginFormInput = {
      focus: sinon.stub()
    }
    loginForm = {
      hide: sinon.stub(),
      show: sinon.stub(),
      find: () => loginFormInput
    }
    forgotPasswordFormInput = {
      focus: sinon.stub()
    }
    forgotPasswordForm = {
      hide: sinon.stub(),
      show: sinon.stub(),
      find: () => forgotPasswordFormInput
    }
    switcher = new LoginFormSwitcher(loginForm, forgotPasswordForm)
  }
})

test('switches to login', () => {
  switcher.switchToLogin()
  ok(forgotPasswordForm.hide.called)
  ok(loginForm.show.called)
  ok(loginFormInput.focus.called)
})

test('switches to forgot password', () => {
  switcher.switchToForgotPassword()
  ok(loginForm.hide.called)
  ok(forgotPasswordForm.show.called)
  ok(forgotPasswordFormInput.focus.called)
})
