/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks'
import {useValidateLaunchSettings} from '../hooks/useValidateLaunchSettings'
import type {Lti1p3RegistrationOverlayState} from '../../registration_overlay/Lti1p3RegistrationOverlayState'
import {mockInternalConfiguration} from './helpers'

describe('useValidateLaunchSettings', () => {
  const validUrl = 'https://example.com'
  const invalidUrl = 'invalid-url'
  const validJwk = JSON.stringify({
    kty: 'RSA',
    alg: 'RS256',
    e: 'AQAB',
    n: '0vx7agoebGcQSuuPiLJXZptN29L...',
    kid: 'key-id',
    use: 'sig',
  })
  const invalidJwk = '{invalid-jwk}'

  const internalConfig = mockInternalConfiguration()

  const createLaunchSettings = (
    overrides: Partial<Lti1p3RegistrationOverlayState['launchSettings']> = {},
  ): Lti1p3RegistrationOverlayState['launchSettings'] => ({
    redirectURIs: `${validUrl}\n${validUrl}`,
    targetLinkURI: `${validUrl}/launch`,
    openIDConnectInitiationURL: `${validUrl}/init`,
    JwkMethod: 'public_jwk_url',
    JwkURL: `${validUrl}/jwk`,
    domain: `example.com`,
    customFields: 'field1=value1\nfield2=value2',
    ...overrides,
  })

  it('should return no errors for valid launch settings', () => {
    const launchSettings = createLaunchSettings()

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(Object.values(result.current)).toEqual([[], [], [], [], [], []])
  })

  it('should return error for invalid redirect URIs', () => {
    const launchSettings = createLaunchSettings({
      redirectURIs: `${validUrl}\n${invalidUrl}`,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.redirectUrisMessages).toEqual([
      {field: 'redirectURIs', text: 'Invalid URL', type: 'error'},
    ])
  })

  it('should return error for missing target link URI', () => {
    const launchSettings = createLaunchSettings({
      targetLinkURI: '',
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.targetLinkURIMessages).toEqual([
      {field: 'targetLinkURI', text: 'Required', type: 'error'},
    ])
  })

  it('should return error for invalid target link URI', () => {
    const launchSettings = createLaunchSettings({
      targetLinkURI: invalidUrl,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.targetLinkURIMessages).toEqual([
      {field: 'targetLinkURI', text: 'Invalid URL', type: 'error'},
    ])
  })

  it('should return error for invalid openID Connect Initiation URL', () => {
    const launchSettings = createLaunchSettings({
      openIDConnectInitiationURL: invalidUrl,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.openIDConnectInitiationURLMessages).toEqual([
      {field: 'openIDConnectInitiationURL', text: 'Invalid URL', type: 'error'},
    ])
  })

  it('should return error for missing JWK when method is public_jwk', () => {
    const launchSettings = createLaunchSettings({
      JwkMethod: 'public_jwk',
      Jwk: '',
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.jwkMessages).toEqual([{field: 'Jwk', text: 'Required', type: 'error'}])
  })

  it('should return error for an invalid JWK', () => {
    const launchSettings = createLaunchSettings({
      JwkMethod: 'public_jwk',
      Jwk: invalidJwk,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.jwkMessages).toEqual([{field: 'Jwk', text: 'Invalid JWK', type: 'error'}])
  })

  it("shouldn't return an error for a valid JWK", () => {
    const launchSettings = createLaunchSettings({
      JwkMethod: 'public_jwk',
      Jwk: validJwk,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.jwkMessages).toEqual([])
  })

  it('should return error for missing JWK URL when method is public_jwk_url', () => {
    const launchSettings = createLaunchSettings({
      JwkMethod: 'public_jwk_url',
      JwkURL: '',
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.jwkMessages).toEqual([{field: 'JwkURL', text: 'Required', type: 'error'}])
  })

  it('should return error for invalid JWK URL', () => {
    const launchSettings = createLaunchSettings({
      JwkMethod: 'public_jwk_url',
      JwkURL: invalidUrl,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.jwkMessages).toEqual([
      {field: 'JwkURL', text: 'Invalid URL', type: 'error'},
    ])
  })

  it('should return error for invalid domain', () => {
    const launchSettings = createLaunchSettings({
      domain: invalidUrl,
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.domainMessages).toEqual([
      {
        field: 'domain',
        text: 'Invalid Domain. Please ensure the domain does not start with http:// or https://.',
        type: 'error',
      },
    ])
  })

  it('should return error for invalid custom fields format', () => {
    const launchSettings = createLaunchSettings({
      customFields: 'invalidCustomField',
    })

    const {result} = renderHook(() => useValidateLaunchSettings(launchSettings))

    expect(result.current.customFieldsMessages).toEqual([
      {field: 'customFields', text: 'Invalid Format', type: 'error'},
    ])
  })
})
