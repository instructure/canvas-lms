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

import authenticationProviders from 'authentication_providers'

let fixtureNode = null
const appendFixtureHtml = function(html) {
  const element = document.createElement('div')
  element.innerHTML = html
  fixtureNode.appendChild(element)
}

QUnit.module('AuthenticationProviders.changedAuthType', {
  setup() {
    fixtureNode = document.getElementById('fixtures')
  },
  teardown() {
    fixtureNode.innerHTML = ''
  }
})

test('it hides new auth forms', () => {
  appendFixtureHtml(`
    <form id='42_form' class='auth-form-container--new'>
      <span>Here is a different new form</span>
    </form>
  `)
  authenticationProviders.changedAuthType('saml')
  const newForm = document.getElementById('42_form')
  equal(newForm.style.display, 'none')
})

test('it reveals a matching form if present', () => {
  appendFixtureHtml(`
    <form id='saml_form' style='display:none;'>
      <span>Here is the new form</span>
    </form>
  `)
  authenticationProviders.changedAuthType('saml')
  const newForm = document.getElementById('saml_form')
  equal(newForm.style.display, '')
})

test("it hides the 'nothing picked' message if present", () => {
  appendFixtureHtml("<div id='no_auth'>No auth thingy picked</div>")
  authenticationProviders.changedAuthType('ldap')
  const noAuthDiv = document.getElementById('no_auth')
  equal(noAuthDiv.style.display, 'none')
})
