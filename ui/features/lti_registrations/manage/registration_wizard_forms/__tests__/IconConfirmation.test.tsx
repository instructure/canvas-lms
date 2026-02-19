/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {IconConfirmation} from '../IconConfirmation'
import {LtiPlacements, type LtiPlacement} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {ZAccountId} from '../../model/AccountId'
import {ZLtiRegistrationUpdateRequestId} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'

const mockInternalConfig = (placements: LtiPlacement[]): InternalLtiConfiguration => ({
  title: 'Test Tool',
  target_link_uri: 'https://example.com',
  oidc_initiation_url: 'https://example.com/oidc',
  custom_fields: {},
  scopes: [],
  placements: placements.map(placement => ({
    placement,
    message_type: 'LtiResourceLinkRequest' as const,
  })),
})

const mockUpdateRequest = (placements: LtiPlacement[]): LtiRegistrationUpdateRequest => ({
  id: ZLtiRegistrationUpdateRequestId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  internal_lti_configuration: mockInternalConfig(placements),
  created_by: null,
  comment: null,
  status: 'pending',
})

const mockRegistration = (placements: LtiPlacement[]): LtiRegistrationWithConfiguration => ({
  id: ZLtiRegistrationId.parse('1'),
  account_id: ZAccountId.parse('1'),
  icon_url: null,
  name: 'Test Tool',
  admin_nickname: null,
  workflow_state: 'active',
  created_at: new Date(),
  updated_at: new Date(),
  vendor: null,
  description: null,
  internal_service: false,
  developer_key_id: ZDeveloperKeyId.parse('1'),
  ims_registration_id: null,
  manual_configuration_id: null,
  configuration: mockInternalConfig(placements),
})

describe('IconConfirmation', () => {
  const defaultProps = () => ({
    internalConfig: mockInternalConfig([]),
    name: 'Test Tool',
    allPlacements: [] as LtiPlacement[],
    placementIconOverrides: {},
    setPlacementIconUrl: vi.fn(),
    defaultIconUrl: '',
    setDefaultIconUrl: vi.fn(),
    hasSubmitted: false,
  })

  it('shows message when no placements with icons', () => {
    render(<IconConfirmation {...defaultProps()} />)

    expect(
      screen.getByText("This tool doesn't have any placements with configurable icons."),
    ).toBeInTheDocument()
  })

  it('renders existing placements without "Added" section when no update request', () => {
    const allPlacements = [LtiPlacements.GlobalNavigation, LtiPlacements.EditorButton]

    render(
      <IconConfirmation
        {...defaultProps()}
        allPlacements={allPlacements}
        internalConfig={mockInternalConfig(allPlacements)}
      />,
    )

    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.GlobalNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.EditorButton)}),
    ).toBeInTheDocument()
    expect(screen.queryByText('Added')).not.toBeInTheDocument()
  })

  it('separates newly added placements under "Added" section', () => {
    const allPlacements = [
      LtiPlacements.GlobalNavigation,
      LtiPlacements.EditorButton,
      LtiPlacements.TopNavigation,
    ]

    // Existing registration has only 2 placements
    const existingRegistration = mockRegistration([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.EditorButton,
    ])

    // Update request includes both existing and new placements
    const updateRequest = mockUpdateRequest([
      LtiPlacements.GlobalNavigation,
      LtiPlacements.EditorButton,
      LtiPlacements.TopNavigation,
    ])

    render(
      <IconConfirmation
        {...defaultProps()}
        allPlacements={allPlacements}
        internalConfig={mockInternalConfig(allPlacements)}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Check that "Added" section exists
    expect(screen.getByRole('heading', {name: 'Added'})).toBeInTheDocument()

    // All placements should be present as headings
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.GlobalNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.EditorButton)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.TopNavigation)}),
    ).toBeInTheDocument()
  })

  it('shows all placements as existing when update request matches existing placements', () => {
    const allPlacements = [LtiPlacements.GlobalNavigation, LtiPlacements.EditorButton]

    const existingRegistration = mockRegistration(allPlacements)
    const updateRequest = mockUpdateRequest(allPlacements)

    render(
      <IconConfirmation
        {...defaultProps()}
        allPlacements={allPlacements}
        internalConfig={mockInternalConfig(allPlacements)}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // "Added" section should not exist since no new placements
    expect(screen.queryByRole('heading', {name: 'Added'})).not.toBeInTheDocument()

    // Both placements should be rendered as headings
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.GlobalNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.EditorButton)}),
    ).toBeInTheDocument()
  })

  it('shows only newly added placements under "Added" section when all are new', () => {
    const allPlacements = [LtiPlacements.TopNavigation, LtiPlacements.EditorButton]

    // Existing registration has no placements with icons
    const existingRegistration = mockRegistration([])

    // Update request adds new placements
    const updateRequest = mockUpdateRequest(allPlacements)

    render(
      <IconConfirmation
        {...defaultProps()}
        allPlacements={allPlacements}
        internalConfig={mockInternalConfig(allPlacements)}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // "Added" section should exist
    expect(screen.getByRole('heading', {name: 'Added'})).toBeInTheDocument()

    // Both placements should be under the Added section as headings
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.TopNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', {name: i18nLtiPlacement(LtiPlacements.EditorButton)}),
    ).toBeInTheDocument()
  })
})
