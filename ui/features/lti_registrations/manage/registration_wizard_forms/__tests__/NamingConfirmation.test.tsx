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
import {NamingConfirmation} from '../NamingConfirmation'
import {LtiPlacements, type LtiPlacement} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import {ZAccountId} from '../../model/AccountId'
import {ZLtiRegistrationUpdateRequestId} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'

const mockUpdateRequest = (
  placements: LtiPlacement[],
  description?: string,
): LtiRegistrationUpdateRequest => ({
  id: ZLtiRegistrationUpdateRequestId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  internal_lti_configuration: {
    title: 'Test Tool',
    target_link_uri: 'https://example.com',
    oidc_initiation_url: 'https://example.com/oidc',
    custom_fields: {},
    scopes: [],
    placements: placements.map(placement => ({
      placement,
      message_type: 'LtiResourceLinkRequest' as const,
      text: undefined,
    })),
    launch_settings: {},
    description,
  },
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
  configuration: {
    title: 'Test Tool',
    target_link_uri: 'https://example.com',
    oidc_initiation_url: 'https://example.com/oidc',
    custom_fields: {},
    scopes: [],
    placements: placements.map(placement => ({
      placement,
      message_type: 'LtiResourceLinkRequest' as const,
      text: undefined,
    })),
  },
})

describe('NamingConfirmation', () => {
  const defaultProps = () => ({
    toolName: 'Test Tool',
    adminNickname: '',
    onUpdateAdminNickname: vi.fn(),
    description: '',
    descriptionPlaceholder: 'Enter description',
    onUpdateDescription: vi.fn(),
    placements: [],
    onUpdatePlacementLabel: vi.fn(),
  })

  it('does not render placement sections when no placements are provided', () => {
    render(<NamingConfirmation {...defaultProps()} />)

    expect(screen.queryByText('Placement Names')).not.toBeInTheDocument()
    expect(screen.queryByText('Added')).not.toBeInTheDocument()
  })

  it('renders existing placements without "Added" section when no update request', () => {
    const placements = [
      {
        placement: LtiPlacements.CourseNavigation,
        label: '',
        defaultValue: 'Course Nav',
      },
      {
        placement: LtiPlacements.AccountNavigation,
        label: '',
        defaultValue: 'Account Nav',
      },
    ]

    render(<NamingConfirmation {...defaultProps()} placements={placements} />)

    expect(screen.getByText('Placement Names')).toBeInTheDocument()
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
    ).toBeInTheDocument()
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.AccountNavigation)),
    ).toBeInTheDocument()
    expect(screen.queryByText('Added')).not.toBeInTheDocument()
  })

  it('separates newly added placements under "Added" section', () => {
    // All placements need to be passed in the placements prop
    const allPlacements = [
      {
        placement: LtiPlacements.CourseNavigation,
        label: '',
        defaultValue: 'Course Nav',
      },
      {
        placement: LtiPlacements.AccountNavigation,
        label: '',
        defaultValue: 'Account Nav',
      },
      {
        placement: LtiPlacements.LinkSelection,
        label: '',
        defaultValue: 'Link Selection',
      },
      {
        placement: LtiPlacements.AssignmentSelection,
        label: '',
        defaultValue: 'Assignment Selection',
      },
    ]

    // Existing registration has only 2 placements
    const existingRegistration = mockRegistration([
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
      <NamingConfirmation
        {...defaultProps()}
        placements={allPlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Check that "Added" section exists
    expect(screen.getByText('Added')).toBeInTheDocument()

    // Get all placement inputs
    const courseNavInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.CourseNavigation),
    )
    const accountNavInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.AccountNavigation),
    )
    const linkSelectionInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.LinkSelection),
    )
    const assignmentSelectionInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.AssignmentSelection),
    )

    // All placements should be present
    expect(courseNavInputs).toHaveLength(1)
    expect(accountNavInputs).toHaveLength(1)
    expect(linkSelectionInputs).toHaveLength(1)
    expect(assignmentSelectionInputs).toHaveLength(1)
  })

  it('shows all placements as existing when update request matches existing placements', () => {
    const placements = [
      {
        placement: LtiPlacements.CourseNavigation,
        label: '',
        defaultValue: 'Course Nav',
      },
      {
        placement: LtiPlacements.AccountNavigation,
        label: '',
        defaultValue: 'Account Nav',
      },
    ]

    const existingRegistration = mockRegistration([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    render(
      <NamingConfirmation
        {...defaultProps()}
        placements={placements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // "Added" section should not exist since no new placements
    expect(screen.queryByText('Added')).not.toBeInTheDocument()

    // Both placements should be rendered in the main section
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
    ).toBeInTheDocument()
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.AccountNavigation)),
    ).toBeInTheDocument()
  })

  it('shows only newly added placements under "Added" section when all are new', () => {
    // All placements in the placements prop
    const allPlacements = [
      {
        placement: LtiPlacements.LinkSelection,
        label: '',
        defaultValue: 'Link Selection',
      },
      {
        placement: LtiPlacements.AssignmentSelection,
        label: '',
        defaultValue: 'Assignment Selection',
      },
    ]

    // Existing registration has no placements
    const existingRegistration = mockRegistration([])

    // Update request adds new placements
    const updateRequest = mockUpdateRequest([
      LtiPlacements.LinkSelection,
      LtiPlacements.AssignmentSelection,
    ])

    render(
      <NamingConfirmation
        {...defaultProps()}
        placements={allPlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // "Added" section should exist
    expect(screen.getByText('Added')).toBeInTheDocument()

    // Both placements should be under the Added section
    expect(screen.getByLabelText(i18nLtiPlacement(LtiPlacements.LinkSelection))).toBeInTheDocument()
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.AssignmentSelection)),
    ).toBeInTheDocument()
  })

  it('correctly handles placements when update request has fewer placements than existing', () => {
    const placements = [
      {
        placement: LtiPlacements.CourseNavigation,
        label: '',
        defaultValue: 'Course Nav',
      },
      {
        placement: LtiPlacements.AccountNavigation,
        label: '',
        defaultValue: 'Account Nav',
      },
      {
        placement: LtiPlacements.LinkSelection,
        label: '',
        defaultValue: 'Link Selection',
      },
    ]

    // Existing registration has all 3 placements
    const existingRegistration = mockRegistration([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.LinkSelection,
    ])

    // Update request only has 2 of the 3 existing placements (LinkSelection is being removed)
    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])

    render(
      <NamingConfirmation
        {...defaultProps()}
        placements={placements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // No newly added placements, so no "Added" section
    expect(screen.queryByText('Added')).not.toBeInTheDocument()

    // Only the two placements in the update request should be rendered
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
    ).toBeInTheDocument()
    expect(
      screen.getByLabelText(i18nLtiPlacement(LtiPlacements.AccountNavigation)),
    ).toBeInTheDocument()

    // LinkSelection was removed, so it should NOT be rendered
    expect(
      screen.queryByLabelText(i18nLtiPlacement(LtiPlacements.LinkSelection)),
    ).not.toBeInTheDocument()
  })

  it('maintains correct structure with mixed existing and new placements', () => {
    // All placements need to be in placements prop
    const allPlacements = [
      {
        placement: LtiPlacements.CourseNavigation,
        label: 'Custom Course Nav',
        defaultValue: 'Course Nav',
      },
      {
        placement: LtiPlacements.LinkSelection,
        label: '',
        defaultValue: 'Link Selection',
      },
    ]

    // Existing registration has only CourseNavigation
    const existingRegistration = mockRegistration([LtiPlacements.CourseNavigation])

    // Update request includes both existing and new placements
    const updateRequest = mockUpdateRequest([
      LtiPlacements.CourseNavigation,
      LtiPlacements.LinkSelection,
    ])

    render(
      <NamingConfirmation
        {...defaultProps()}
        placements={allPlacements}
        existingRegistration={existingRegistration}
        registrationUpdateRequest={updateRequest}
      />,
    )

    // Both sections should exist
    expect(screen.getByText('Placement Names')).toBeInTheDocument()
    expect(screen.getByText('Added')).toBeInTheDocument()

    // Verify both placements are present
    const courseNavInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.CourseNavigation),
    )
    const linkSelectionInputs = screen.getAllByLabelText(
      i18nLtiPlacement(LtiPlacements.LinkSelection),
    )

    expect(courseNavInputs).toHaveLength(1)
    expect(linkSelectionInputs).toHaveLength(1)

    // Verify the existing placement has the custom label
    expect(courseNavInputs[0]).toHaveValue('Custom Course Nav')
  })
})
