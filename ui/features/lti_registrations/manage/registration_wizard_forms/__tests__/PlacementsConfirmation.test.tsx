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
import {PlacementsConfirmation} from '../PlacementsConfirmation'
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

const mockExistingRegistration = (
  placements: LtiPlacement[],
): LtiRegistrationWithConfiguration => ({
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

describe('PlacementsConfirmation', () => {
  const defaultProps = () => ({
    appName: 'Test Tool',
    enabledPlacements: [] as LtiPlacement[],
    availablePlacements: [] as LtiPlacement[],
    courseNavigationDefaultHidden: false,
    topNavigationAllowFullscreen: false,
    onTogglePlacement: vi.fn(),
    onToggleDefaultDisabled: vi.fn(),
    onToggleAllowFullscreen: vi.fn(),
  })

  it('shows message when no placements available', () => {
    render(<PlacementsConfirmation {...defaultProps()} />)

    expect(
      screen.getByText(
        "This tool has not requested access to any placements. If installed, it will have access to the LTI APIs but won't be visible for users to launch. The app can be managed via the Manage Apps page.",
      ),
    ).toBeInTheDocument()
  })

  it('renders available placements without "Added" or "Removed" sections when no update request', () => {
    const availablePlacements = [LtiPlacements.CourseNavigation, LtiPlacements.AccountNavigation]

    render(<PlacementsConfirmation {...defaultProps()} availablePlacements={availablePlacements} />)

    expect(screen.getByText(i18nLtiPlacement(LtiPlacements.CourseNavigation))).toBeInTheDocument()
    expect(screen.getByText(i18nLtiPlacement(LtiPlacements.AccountNavigation))).toBeInTheDocument()
    expect(screen.queryByText('Added')).not.toBeInTheDocument()
    expect(screen.queryByText('Removed')).not.toBeInTheDocument()
  })

  it('separates newly added placements under "Added" section', () => {
    const availablePlacements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.LinkSelection,
      LtiPlacements.AssignmentSelection,
    ]

    // Existing registration has only 2 placements
    const existingRegistration = mockExistingRegistration([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    // Update request includes both existing and new placements
    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.LinkSelection,
      LtiPlacements.AssignmentSelection,
    ])

    render(
      <PlacementsConfirmation
        {...defaultProps()}
        availablePlacements={availablePlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Check that "Added" section exists
    expect(screen.getByRole('heading', {name: 'Added'})).toBeInTheDocument()

    // All placements should be present as checkboxes
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.CourseNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.AccountNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.LinkSelection)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.AssignmentSelection)}),
    ).toBeInTheDocument()
  })

  it('separates removed placements under "Removed" section', () => {
    const availablePlacements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.LinkSelection,
    ]

    // Existing registration has all 3 placements
    const existingRegistration = mockExistingRegistration(availablePlacements)

    // Update request removes LinkSelection
    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    render(
      <PlacementsConfirmation
        {...defaultProps()}
        availablePlacements={availablePlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Check that "Removed" section exists
    expect(screen.getByRole('heading', {name: 'Removed'})).toBeInTheDocument()

    // Removed placement should be present and disabled
    const linkSelectionCheckboxes = screen.getAllByRole('checkbox', {
      name: i18nLtiPlacement(LtiPlacements.LinkSelection),
    })
    expect(linkSelectionCheckboxes[0]).toBeDisabled()
  })

  it('shows all placements as existing when update request matches existing placements', () => {
    const availablePlacements = [LtiPlacements.CourseNavigation, LtiPlacements.AccountNavigation]

    const existingRegistration = mockExistingRegistration(availablePlacements)
    const updateRequest = mockUpdateRequest(availablePlacements)

    render(
      <PlacementsConfirmation
        {...defaultProps()}
        availablePlacements={availablePlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // No "Added" or "Removed" sections
    expect(screen.queryByRole('heading', {name: 'Added'})).not.toBeInTheDocument()
    expect(screen.queryByRole('heading', {name: 'Removed'})).not.toBeInTheDocument()

    // Both placements should be rendered as checkboxes
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.CourseNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.AccountNavigation)}),
    ).toBeInTheDocument()
  })

  it('shows only newly added placements under "Added" section when all are new', () => {
    const availablePlacements = [LtiPlacements.LinkSelection, LtiPlacements.AssignmentSelection]

    // Existing registration has no placements
    const existingRegistration = mockExistingRegistration([])

    // Update request adds new placements
    const updateRequest = mockUpdateRequest(availablePlacements)

    render(
      <PlacementsConfirmation
        {...defaultProps()}
        availablePlacements={availablePlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // "Added" section should exist
    expect(screen.getByRole('heading', {name: 'Added'})).toBeInTheDocument()

    // Both placements should be under the Added section as checkboxes
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.LinkSelection)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.AssignmentSelection)}),
    ).toBeInTheDocument()
  })

  it('handles both added and removed placements simultaneously', () => {
    const availablePlacements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.LinkSelection,
      LtiPlacements.AccountNavigation,
    ]

    // Existing registration has CourseNavigation and AccountNavigation
    const existingRegistration = mockExistingRegistration([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    // Update request removes AccountNavigation and adds LinkSelection
    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.LinkSelection,
    ])

    render(
      <PlacementsConfirmation
        {...defaultProps()}
        availablePlacements={availablePlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Both sections should exist
    expect(screen.getByRole('heading', {name: 'Added'})).toBeInTheDocument()
    expect(screen.getByRole('heading', {name: 'Removed'})).toBeInTheDocument()

    // Verify placements are present as checkboxes
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.CourseNavigation)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.LinkSelection)}),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('checkbox', {name: i18nLtiPlacement(LtiPlacements.AccountNavigation)}),
    ).toBeInTheDocument()
  })
})
