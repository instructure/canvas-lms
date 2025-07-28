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
import {ReviewScreenWrapper} from '../components/ReviewScreenWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {type Lti1p3RegistrationOverlayState} from '../../registration_overlay/Lti1p3RegistrationOverlayState'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {i18nLtiPrivacyLevelDescription} from '../../model/i18nLtiPrivacyLevel'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'

describe('Review Screen Wrapper', () => {
  beforeEach(() => {
    userEvent.setup()
  })
  const renderComponent = (
    internalConfigOverrides: Partial<InternalLtiConfiguration> = {},
    stateOverrides: Partial<Lti1p3RegistrationOverlayState> = {},
  ) => {
    const internalConfig = mockInternalConfiguration(internalConfigOverrides)
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const state = overlayStore.getState()
    overlayStore.setState({...state, state: {...state.state, ...stateOverrides}})

    const transitionTo = jest.fn()

    render(
      <ReviewScreenWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        transitionTo={transitionTo}
      />,
    )

    return {transitionTo}
  }

  it('renders the ReviewScreen with default settings', () => {
    renderComponent()

    expect(screen.getByText('Review')).toBeInTheDocument()
    expect(screen.getByText('Review your changes before finalizing.')).toBeInTheDocument()
  })

  it('renders the launch settings section', () => {
    renderComponent()

    expect(screen.getByText('Launch Settings')).toBeInTheDocument()
    expect(screen.getByText('Redirect URIs')).toBeInTheDocument()
    expect(screen.getByText('Default Target Link URI')).toBeInTheDocument()
    expect(screen.getByText('OpenID Connect Initiation URL')).toBeInTheDocument()
    expect(screen.getByText('JWK Method')).toBeInTheDocument()
    expect(screen.getByText('Domain')).toBeInTheDocument()
    expect(screen.getByText('Custom Fields')).toBeInTheDocument()
  })

  it('says that no redirect uris are present when none are configured', () => {
    renderComponent({redirect_uris: undefined})

    expect(screen.getByText(/no redirect uris specified/i)).toBeInTheDocument()
  })

  it('displays all redirect URIs', () => {
    renderComponent({
      redirect_uris: ['https://example.com/redirect1', 'https://example.com/redirect2'],
    })

    expect(screen.getByText('https://example.com/redirect1')).toBeInTheDocument()
    expect(screen.getByText('https://example.com/redirect2')).toBeInTheDocument()
  })

  it('says that no custom fields are present when none are configured', () => {
    renderComponent({custom_fields: undefined})

    expect(screen.getByText(/no custom fields specified/i)).toBeInTheDocument()
  })

  it('renders the relevant information for the JWK Method', () => {
    renderComponent({public_jwk_url: 'https://example.com/jwk'})

    expect(screen.getByRole('heading', {name: /Public JWK URL/i})).toBeInTheDocument()
    expect(screen.getByText('https://example.com/jwk')).toBeInTheDocument()
  })

  it('renders an interactable show more button when more than 3 custom fields are configured', async () => {
    renderComponent({
      custom_fields: {
        field1: 'value1',
        field2: 'value2',
        field3: 'value3',
        field4: 'value4',
      },
    })

    expect(screen.queryByText('field4=value4')).not.toBeInTheDocument()
    expect(screen.getByText('Show more')).toBeInTheDocument()

    await userEvent.click(screen.getByText('Show more'))

    expect(screen.getByText('field4=value4')).toBeInTheDocument()
  })

  it('renders the permissions section', () => {
    renderComponent()

    expect(screen.getByText('Permissions')).toBeInTheDocument()
  })

  it('renders the data sharing section', () => {
    renderComponent()

    expect(screen.getByText('Data Sharing')).toBeInTheDocument()
  })

  it('renders the placements section', () => {
    renderComponent()

    expect(screen.getByText('Placements')).toBeInTheDocument()
  })

  it('renders the naming section', () => {
    renderComponent()

    expect(screen.getByText('Naming')).toBeInTheDocument()
  })

  it('renders appropriate text when no nickname is defined', () => {
    renderComponent(
      {},
      {
        naming: {
          nickname: undefined,
          placements: {},
        },
      },
    )

    expect(screen.getByText(/no nickname provided/i)).toBeInTheDocument()
  })

  it('renders the icon URLs section', () => {
    renderComponent()

    expect(screen.getByText('Icon URLs')).toBeInTheDocument()
  })

  it('transitions to the correct step when edit buttons are clicked', async () => {
    const {transitionTo} = renderComponent()

    await userEvent.click(screen.getByText(/Edit Launch Settings/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('LaunchSettings')

    await userEvent.click(screen.getByText(/Edit Permissions/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Permissions')

    await userEvent.click(screen.getByText(/Edit Data Sharing/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('DataSharing')

    await userEvent.click(screen.getByText(/Edit Placements/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Placements')

    await userEvent.click(screen.getByText(/Edit Naming/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Naming')

    await userEvent.click(screen.getByText(/Edit Icon URLs/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Icons')
  })

  it('renders custom fields correctly', () => {
    renderComponent({}, {launchSettings: {customFields: 'field1=value1\nfield2=value2'}})

    expect(screen.getByText('field1=value1')).toBeInTheDocument()
    expect(screen.getByText('field2=value2')).toBeInTheDocument()
  })

  it('renders placements with icons correctly', () => {
    renderComponent(
      {
        placements: [
          {placement: 'editor_button', icon_url: 'https://example.com/icon1.png'},
          {placement: 'global_navigation', icon_url: 'https://example.com/icon2.png'},
        ],
      },
      {
        icons: {
          placements: {
            editor_button: 'https://example.com/foobarbaz',
            global_navigation: 'https://example.com/icon2.png',
          },
        },
      },
    )

    expect(screen.getByText('Default Icon')).toBeInTheDocument()
    expect(screen.getByText('Custom Icon')).toBeInTheDocument()
  })

  it('renders privacy level correctly', () => {
    renderComponent({}, {data_sharing: {privacy_level: 'name_only'}})

    expect(screen.getByText(i18nLtiPrivacyLevelDescription('name_only'))).toBeInTheDocument()
  })

  it('renders scopes correctly', () => {
    renderComponent(
      {},
      {permissions: {scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem']}},
    )

    expect(
      screen.getByText(i18nLtiScope('https://purl.imsglobal.org/spec/lti-ags/scope/lineitem')),
    ).toBeInTheDocument()
  })
})
