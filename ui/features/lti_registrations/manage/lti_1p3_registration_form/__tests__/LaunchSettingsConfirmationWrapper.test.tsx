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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {LaunchSettingsConfirmationWrapper} from '../components/LaunchSettingsConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {getInputIdForField} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'

describe('LaunchSettings', () => {
  beforeEach(() => {
    userEvent.setup()
  })

  it('renders the form correctly', () => {
    const config = mockInternalConfiguration({
      redirect_uris: ['https://example.com/launch'],
      domain: 'example.com',
      public_jwk_url: 'https://example.com/jwks',
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')
    render(
      <LaunchSettingsConfirmationWrapper
        internalConfig={config}
        overlayStore={overlayStore}
        onPreviousClicked={jest.fn()}
        onNextClicked={jest.fn()}
        reviewing={false}
      />,
    )

    const redirectUris = screen.getByLabelText(/Redirect URIs/i)
    const defaultTargetLinkUri = screen.getByLabelText(/Default Target Link URI/i)
    const oidcInitiationUrl = screen.getByLabelText(/OpenID Connect Initiation URL/i)
    const jwkUrl = screen.getByLabelText(/^JWK URL$/i)
    const domain = screen.getByLabelText(/Domain/i)
    const customFields = screen.getByTestId('custom-fields')

    expect(redirectUris).toBeInTheDocument()
    expect(redirectUris).toHaveValue(config.redirect_uris!.join('\n'))
    expect(defaultTargetLinkUri).toBeInTheDocument()
    expect(defaultTargetLinkUri).toHaveAttribute('placeholder', config.target_link_uri)
    expect(oidcInitiationUrl).toBeInTheDocument()
    expect(oidcInitiationUrl).toHaveValue(config.oidc_initiation_url)
    expect(jwkUrl).toBeInTheDocument()
    expect(jwkUrl).toHaveValue(config.public_jwk_url)
    expect(domain).toBeInTheDocument()
    expect(domain).toHaveAttribute('placeholder', config.domain)
    expect(customFields).toBeInTheDocument()
    expect(customFields).toHaveAttribute(
      'placeholder',
      Object.entries(config.custom_fields!).reduce((acc, [key, value]) => {
        return acc + `${key}=${value}\n`
      }, ''),
    )
  })

  it('handles input changes', async () => {
    const config = mockInternalConfiguration({
      redirect_uris: ['https://example.com/launch'],
      domain: 'example.com',
      public_jwk_url: 'https://example.com/jwks',
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')
    render(
      <LaunchSettingsConfirmationWrapper
        internalConfig={config}
        overlayStore={overlayStore}
        onPreviousClicked={jest.fn()}
        onNextClicked={jest.fn()}
        reviewing={false}
      />,
    )
    const redirectURIs = screen.getByLabelText(/Redirect URIs/i)
    const expectedRedirectUris = [
      'https://example.com',
      'https://example.com/launch',
      'https://example.com/launch2',
    ]
    await userEvent.clear(redirectURIs)
    await userEvent.paste(expectedRedirectUris.join('\n'))

    expect(redirectURIs).toHaveValue(expectedRedirectUris.join('\n'))

    const targetLinkUri = screen.getByLabelText(/Default Target Link URI/i)
    await userEvent.clear(targetLinkUri)
    await userEvent.paste('https://otherexample.com')
    expect(targetLinkUri).toHaveValue('https://otherexample.com')

    const oidcInitiationUrl = screen.getByLabelText(/OpenID Connect Initiation URL/i)
    await userEvent.clear(oidcInitiationUrl)
    await userEvent.paste('https://example.com/init')

    expect(oidcInitiationUrl).toHaveValue('https://example.com/init')

    const jwkUrl = screen.getByLabelText('JWK URL')
    await userEvent.clear(jwkUrl)
    await userEvent.paste('https://example.com/jwk')
    expect(jwkUrl).toHaveValue('https://example.com/jwk')

    const domain = screen.getByLabelText('Domain')
    await userEvent.clear(domain)
    await userEvent.paste('foo.com')
    expect(domain).toHaveValue('foo.com')

    const customFields = screen.getByTestId('custom-fields')
    await userEvent.clear(customFields)
    await userEvent.paste('name=value\n')

    expect(customFields).toHaveValue('name=value\n')
  })
})

it('focuses invalid inputs if any fields are invalid', async () => {
  const config = mockInternalConfiguration({
    redirect_uris: ['https://example.com/launch'],
    domain: 'example.com',
    public_jwk_url: 'https://example.com/jwks',
  })
  const overlayStore = createLti1p3RegistrationOverlayStore(config, '')
  const onNextClicked = jest.fn()
  render(
    <LaunchSettingsConfirmationWrapper
      internalConfig={config}
      overlayStore={overlayStore}
      onPreviousClicked={jest.fn()}
      onNextClicked={onNextClicked}
      reviewing={false}
    />,
  )
  const nextButton = screen.getByRole('button', {name: /Next/i})
  const redirectURIs = screen.getByLabelText(/Redirect URIs/i)
  await userEvent.clear(redirectURIs)
  await userEvent.paste('http:<<<>>')
  await userEvent.tab()
  await userEvent.click(nextButton)
  expect(onNextClicked).not.toHaveBeenCalled()
  expect(redirectURIs).toHaveFocus()

  await userEvent.clear(redirectURIs)
  await userEvent.paste('https://example.com/launch')

  const domain = screen.getByLabelText('Domain')
  await userEvent.clear(domain)
  await userEvent.paste('domain00---.com.')
  await userEvent.tab()
  await userEvent.click(nextButton)
  expect(onNextClicked).not.toHaveBeenCalled()
  expect(domain).toHaveFocus()

  await userEvent.clear(domain)
  await userEvent.paste('example.com')
  await userEvent.click(nextButton)
  expect(onNextClicked).toHaveBeenCalled()
})
