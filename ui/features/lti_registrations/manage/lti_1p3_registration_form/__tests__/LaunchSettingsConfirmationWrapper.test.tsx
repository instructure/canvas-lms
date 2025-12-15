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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {LaunchSettingsConfirmationWrapper} from '../components/LaunchSettingsConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'

describe('LaunchSettings', () => {
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
        onPreviousClicked={vi.fn()}
        onNextClicked={vi.fn()}
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
    const user = userEvent.setup()
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
        onPreviousClicked={vi.fn()}
        onNextClicked={vi.fn()}
        reviewing={false}
      />,
    )
    const redirectURIs = screen.getByLabelText(/Redirect URIs/i)
    const expectedRedirectUris = [
      'https://example.com',
      'https://example.com/launch',
      'https://example.com/launch2',
    ]
    await user.clear(redirectURIs)
    await user.paste(expectedRedirectUris.join('\n'))

    expect(redirectURIs).toHaveValue(expectedRedirectUris.join('\n'))

    const targetLinkUri = screen.getByLabelText(/Default Target Link URI/i)
    await user.clear(targetLinkUri)
    await user.paste('https://otherexample.com')
    expect(targetLinkUri).toHaveValue('https://otherexample.com')

    const oidcInitiationUrl = screen.getByLabelText(/OpenID Connect Initiation URL/i)
    await user.clear(oidcInitiationUrl)
    await user.paste('https://example.com/init')

    expect(oidcInitiationUrl).toHaveValue('https://example.com/init')

    const jwkUrl = screen.getByLabelText('JWK URL')
    await user.clear(jwkUrl)
    await user.paste('https://example.com/jwk')
    expect(jwkUrl).toHaveValue('https://example.com/jwk')

    const domain = screen.getByLabelText('Domain')
    await user.clear(domain)
    await user.paste('foo.com')
    expect(domain).toHaveValue('foo.com')

    const customFields = screen.getByTestId('custom-fields')
    await user.clear(customFields)
    await user.paste('name=value\n')

    expect(customFields).toHaveValue('name=value\n')
  })
})

it('renders a popover on hovering over the custom fields info button', async () => {
  const user = userEvent.setup()
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
      onPreviousClicked={vi.fn()}
      onNextClicked={vi.fn()}
      reviewing={false}
    />,
  )

  // Find the info button - it has the accessible name "Custom Fields Help"
  const infoButton = screen.getByRole('button', {name: 'Custom Fields Help'})

  expect(infoButton).toBeInTheDocument()
  expect(infoButton).toHaveAttribute('id', 'custom_fields_render_trigger')

  await user.hover(infoButton)

  // Wait for popover to appear and check for the documentation link
  await waitFor(() => {
    // Get all Canvas documentation links and find the one with the correct href
    const links = screen.getAllByRole('link', {name: /Canvas documentation/i})
    const customFieldsDocLink = links.find(
      link =>
        link.getAttribute('href') ===
        'https://canvas.instructure.com/doc/api/file.tools_variable_substitutions.html',
    )
    expect(customFieldsDocLink).toBeInTheDocument()
  })
})

it('focuses invalid inputs if any fields are invalid', async () => {
  const user = userEvent.setup()
  const config = mockInternalConfiguration({
    redirect_uris: ['https://example.com/launch'],
    domain: 'example.com',
    public_jwk_url: 'https://example.com/jwks',
  })
  const overlayStore = createLti1p3RegistrationOverlayStore(config, '')
  const onNextClicked = vi.fn()
  render(
    <LaunchSettingsConfirmationWrapper
      internalConfig={config}
      overlayStore={overlayStore}
      onPreviousClicked={vi.fn()}
      onNextClicked={onNextClicked}
      reviewing={false}
    />,
  )
  const nextButton = screen.getByRole('button', {name: /Next/i})
  const redirectURIs = screen.getByLabelText(/Redirect URIs/i)
  await user.clear(redirectURIs)
  await user.paste('http:<<<>>')
  await user.tab()
  // Small delay to ensure validation runs
  await new Promise(resolve => setTimeout(resolve, 10))
  await user.click(nextButton)
  expect(onNextClicked).not.toHaveBeenCalled()
  expect(redirectURIs).toHaveFocus()

  await user.clear(redirectURIs)
  await user.paste('https://example.com/launch')

  const domain = screen.getByLabelText('Domain')
  await user.clear(domain)
  await user.paste('domain00---.com.')
  await user.tab()
  // Small delay to ensure validation runs
  await new Promise(resolve => setTimeout(resolve, 10))
  await user.click(nextButton)
  expect(onNextClicked).not.toHaveBeenCalled()
  expect(domain).toHaveFocus()

  await user.clear(domain)
  await user.paste('example.com')
  await user.click(nextButton)
  expect(onNextClicked).toHaveBeenCalled()
})
