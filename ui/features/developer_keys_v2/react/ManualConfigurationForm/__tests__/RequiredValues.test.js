/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import get from 'lodash/get'

import RequiredValues from '../RequiredValues'

const props = (overrides = {}) => {
  return {
    toolConfiguration: {
      title: 'This is a title',
      description: 'asdfsdf',
      target_link_uri: 'http://example.com',
      oidc_initiation_url: 'http://example.com/initiate',
      // public_jwk is first stringified in the constructor before being JSON.parse()d again:
      public_jwk: {kty: 'RSA', alg: 'RSA256', n: '', e: '', kid: '', use: ''},
      ...overrides,
    },
    flashError: () => {},
    ...overrides,
  }
}

it('generates the toolConfiguration', () => {
  const wrapper = mount(<RequiredValues {...props()} />)
  const toolConfig = wrapper.instance().generateToolConfigurationPart()
  expect(Object.keys(toolConfig).length).toEqual(5)
})

const checkToolConfigPart = (toolConfig, path, value) => {
  expect(get(toolConfig, path)).toEqual(value)
}

const checkChange = (path, funcName, value, expectedValue = null) => {
  const wrapper = mount(<RequiredValues {...props()} />)

  wrapper.instance()[funcName]({target: {value}})
  checkToolConfigPart(
    wrapper.instance().generateToolConfigurationPart(),
    path,
    expectedValue || value
  )
}

it('changes the output when domain changes', () => {
  checkChange(['title'], 'handleTitleChange', 'New Title')
})

it('changes the output when tool_id changes', () => {
  checkChange(['description'], 'handleDescriptionChange', 'qwerty')
})

it('changes the output when icon_url changes', () => {
  checkChange(
    ['oidc_initiation_url'],
    'handleOidcInitiationUrlChange',
    'http://example.com/new/login'
  )
})

it('changes the output when target_link_uri changes', () => {
  checkChange(['target_link_uri'], 'handleTargetLinkUriChange', 'http://example.com/new')
})

it('changes the output when public_jwk changes', () => {
  checkChange(['public_jwk'], 'handlePublicJwkChange', '{}', {})
})

it('is valid when valid', () => {
  const wrapper = mount(<RequiredValues {...props()} />)
  expect(wrapper.instance().valid()).toEqual(true)
})

it('is invalid when invalid inputs', () => {
  const flashError = jest.fn()
  const wrapper = mount(<RequiredValues {...props({target_link_uri: '', flashError})} />)
  expect(wrapper.instance().valid()).toEqual(false)
  expect(flashError).toHaveBeenCalled()
})

it('is invalid when the public JWK is missing a field', () => {
  const flashError = jest.fn()
  const public_jwk = {kty: 'RSA', alg: 'RSA256', e: '', kid: '', use: ''} // no 'n'
  const wrapper = mount(<RequiredValues {...props({public_jwk, flashError})} />)
  expect(wrapper.instance().valid()).toEqual(false)
  expect(flashError).toHaveBeenCalled()
})

it('is valid if the public JWK is empty but a URL is given', () => {
  const flashError = jest.fn()
  const public_jwk = {}
  const public_jwk_url = 'https://www.instructure.com/public_key_url'
  const wrapper = mount(<RequiredValues {...props({public_jwk, flashError, public_jwk_url})} />)
  expect(wrapper.instance().valid()).toEqual(true)
})
