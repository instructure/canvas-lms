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
import {render} from '@testing-library/react'
import get from 'lodash/get'

import RequiredValues from '../RequiredValues'

const props = ({configOverrides = {}, overrides = {}}) => {
  return {
    toolConfiguration: {
      title: 'This is a title',
      description: 'asdfsdf',
      target_link_uri: 'http://example.com',
      oidc_initiation_url: 'http://example.com/initiate',
      // public_jwk is first stringified in the constructor before being JSON.parse()d again:
      public_jwk: {kty: 'RSA', alg: 'RSA256', n: '', e: '', kid: '', use: ''},
      ...configOverrides,
    },
    ...overrides,
  }
}

it('generates the toolConfiguration', () => {
  const ref = React.createRef()
  const p = props({overrides: {ref}})
  render(<RequiredValues {...p} />)
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(Object.keys(toolConfig)).toHaveLength(5)
})

const checkToolConfigPart = (toolConfig, path, value) => {
  expect(get(toolConfig, path)).toEqual(value)
}

const checkChange = (path, funcName, value, expectedValue = null) => {
  const ref = React.createRef()
  render(<RequiredValues {...props({overrides: {ref}})} />)

  ref.current[funcName]({target: {value}})
  checkToolConfigPart(ref.current.generateToolConfigurationPart(), path, expectedValue || value)
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
    'http://example.com/new/login',
  )
})

it('changes the output when target_link_uri changes', () => {
  checkChange(['target_link_uri'], 'handleTargetLinkUriChange', 'http://example.com/new')
})

it('changes the output when public_jwk changes', () => {
  checkChange(['public_jwk'], 'handlePublicJwkChange', '{}', {})
})

it('is valid when valid', () => {
  const ref = React.createRef()
  render(<RequiredValues {...props({overrides: {ref}})} />)
  expect(ref.current.valid()).toEqual(true)
})

it('is invalid when invalid inputs', () => {
  const ref = React.createRef()
  render(<RequiredValues {...props({overrides: {ref}, configOverrides: {target_link_uri: ''}})} />)
  expect(ref.current.valid()).toEqual(false)
})

it('is invalid when the public JWK is missing a field', () => {
  const ref = React.createRef()
  const overrides = {ref}
  const configOverrides = {
    public_jwk: {kty: 'RSA', alg: 'RSA256', e: '', kid: '', use: ''}, // no 'n'
  }
  render(<RequiredValues {...props({overrides, configOverrides})} />)
  expect(ref.current.valid()).toEqual(false)
})

it('is valid if the public JWK is empty but a URL is given', () => {
  const ref = React.createRef()
  const public_jwk = {}
  const public_jwk_url = 'https://www.instructure.com/public_key_url'
  const overrides = {ref}
  const configOverrides = {
    public_jwk,
    public_jwk_url,
  }
  render(<RequiredValues {...props({configOverrides, overrides})} />)
  expect(ref.current.valid()).toEqual(true)
})
