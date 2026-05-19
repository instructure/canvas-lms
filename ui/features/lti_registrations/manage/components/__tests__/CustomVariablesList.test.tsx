/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {ZAccountId} from '../../model/AccountId'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {ZLtiRegistrationUpdateRequestId} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {CustomVariablesList} from '../CustomVariablesList'

const mockConfig = (overrides?: Partial<InternalLtiConfiguration>): InternalLtiConfiguration => ({
  title: 'Test Tool',
  description: 'Test Description',
  target_link_uri: 'https://example.com',
  oidc_initiation_url: 'https://example.com/oidc',
  custom_fields: {},
  scopes: [],
  placements: [],
  launch_settings: {},
  ...overrides,
})

const mockUpdateRequest = (
  config?: Partial<InternalLtiConfiguration>,
): LtiRegistrationUpdateRequest => ({
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  internal_lti_configuration: mockConfig(config),
  id: ZLtiRegistrationUpdateRequestId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
})

describe('CustomVariablesList', () => {
  const originalEnv = window.ENV

  beforeEach(() => {
    window.ENV = {
      ...originalEnv,
      FEATURES: {
        substitution_variable_display: true,
      },
    }
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  describe('feature flag behavior', () => {
    it('renders null when feature flag is disabled', () => {
      window.ENV.FEATURES = {substitution_variable_display: false}

      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      const {container} = render(<CustomVariablesList internalConfiguration={config} />)
      expect(container.firstChild).toBeNull()
    })

    it('renders when feature flag is enabled', () => {
      window.ENV.FEATURES = {substitution_variable_display: true}

      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)
      expect(screen.getByText('Extra Data')).toBeInTheDocument()
    })
  })

  describe('empty state behavior', () => {
    it('renders null when internalConfiguration is undefined', () => {
      const {container} = render(<CustomVariablesList internalConfiguration={undefined} />)
      expect(container.firstChild).toBeNull()
    })

    it('renders null when no substitution variables are present', () => {
      const config = mockConfig({
        custom_fields: {
          regular_field: 'not_a_variable',
        },
      })

      const {container} = render(<CustomVariablesList internalConfiguration={config} />)
      expect(container.firstChild).toBeNull()
    })

    it('renders null when config has no custom fields', () => {
      const config = mockConfig()
      const {container} = render(<CustomVariablesList internalConfiguration={config} />)
      expect(container.firstChild).toBeNull()
    })
  })

  describe('rendering unchanged variables', () => {
    it('renders a list of unchanged substitution variables', () => {
      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      expect(screen.getByText('Extra Data')).toBeInTheDocument()
      expect(
        screen.getByText('This app will receive the following additional data in launches:'),
      ).toBeInTheDocument()
      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
    })

    it('does not show Added or Removed sections when no update request', () => {
      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      expect(screen.queryByText('Added')).not.toBeInTheDocument()
      expect(screen.queryByText('Removed')).not.toBeInTheDocument()
    })

    it('creates proper documentation links for variables', () => {
      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      const link = screen.getByRole('link', {name: '$Canvas.user.id'})
      expect(link).toHaveAttribute(
        'href',
        '/doc/api/file.tools_variable_substitutions.html#canvas-user-id',
      )
      expect(link).toHaveAttribute('target', '_blank')
    })

    it('formats documentation URLs correctly for variables with dots', () => {
      const config = mockConfig({
        custom_fields: {
          person_name: '$Person.name.full',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      const link = screen.getByRole('link', {name: '$Person.name.full'})
      expect(link).toHaveAttribute(
        'href',
        '/doc/api/file.tools_variable_substitutions.html#person-name-full',
      )
    })
  })

  describe('rendering added variables', () => {
    it('shows Added section when variables are added', () => {
      const originalConfig = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      const updateRequest = mockUpdateRequest({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
        },
      })

      render(
        <CustomVariablesList
          internalConfiguration={originalConfig}
          registrationUpdateRequest={updateRequest}
        />,
      )

      expect(screen.getByText('Added')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
    })

    it('shows multiple added variables', () => {
      const originalConfig = mockConfig()

      const updateRequest = mockUpdateRequest({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
          assignment_id: '$Canvas.assignment.id',
        },
      })

      render(
        <CustomVariablesList
          internalConfiguration={originalConfig}
          registrationUpdateRequest={updateRequest}
        />,
      )

      expect(screen.getByText('Added')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.assignment.id')).toBeInTheDocument()
    })
  })

  describe('rendering removed variables', () => {
    it('shows Removed section when variables are removed', () => {
      const originalConfig = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
        },
      })

      const updateRequest = mockUpdateRequest({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      })

      render(
        <CustomVariablesList
          internalConfiguration={originalConfig}
          registrationUpdateRequest={updateRequest}
        />,
      )

      expect(screen.getByText('Removed')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
    })

    it('shows multiple removed variables', () => {
      const originalConfig = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
          assignment_id: '$Canvas.assignment.id',
        },
      })

      const updateRequest = mockUpdateRequest()

      render(
        <CustomVariablesList
          internalConfiguration={originalConfig}
          registrationUpdateRequest={updateRequest}
        />,
      )

      expect(screen.getByText('Removed')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.assignment.id')).toBeInTheDocument()
    })
  })

  describe('rendering mixed changes', () => {
    it('shows all three sections when variables are added, removed, and unchanged', () => {
      const originalConfig = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
          course_id: '$Canvas.course.id',
        },
      })

      const updateRequest = mockUpdateRequest({
        custom_fields: {
          user_id: '$Canvas.user.id', // unchanged
          assignment_id: '$Canvas.assignment.id', // added
        },
      })

      render(
        <CustomVariablesList
          internalConfiguration={originalConfig}
          registrationUpdateRequest={updateRequest}
        />,
      )

      // Unchanged section (implicit - no heading)
      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()

      // Added section
      expect(screen.getByText('Added')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.assignment.id')).toBeInTheDocument()

      // Removed section
      expect(screen.getByText('Removed')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
    })
  })

  describe('deduplication behavior', () => {
    it('shows each variable only once even if present in multiple places', () => {
      const config = mockConfig({
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
        launch_settings: {
          custom_fields: {
            user_id_again: '$Canvas.user.id',
          },
        },
        placements: [
          {
            placement: 'course_navigation',
            custom_fields: {
              user_id_third: '$Canvas.user.id',
            },
          },
        ],
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      const links = screen.getAllByText('$Canvas.user.id')
      expect(links).toHaveLength(1) // Should only appear once
    })
  })

  describe('filtering behavior', () => {
    it('only shows Canvas substitution variables, not custom variables', () => {
      const config = mockConfig({
        custom_fields: {
          canvas_var: '$Canvas.user.id',
          custom_var: '$my.custom.variable',
          regular_field: 'not_a_variable',
        },
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()
      expect(screen.queryByText('$my.custom.variable')).not.toBeInTheDocument()
      expect(screen.queryByText('not_a_variable')).not.toBeInTheDocument()
    })
  })

  describe('variables from different configuration levels', () => {
    it('displays variables from all configuration levels', () => {
      const config = mockConfig({
        custom_fields: {
          base_var: '$Canvas.user.id',
        },
        launch_settings: {
          custom_fields: {
            launch_var: '$Canvas.course.id',
          },
        },
        placements: [
          {
            placement: 'course_navigation',
            custom_fields: {
              placement_var: '$Canvas.assignment.id',
            },
          },
        ],
      })

      render(<CustomVariablesList internalConfiguration={config} />)

      expect(screen.getByText('$Canvas.user.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.course.id')).toBeInTheDocument()
      expect(screen.getByText('$Canvas.assignment.id')).toBeInTheDocument()
    })
  })
})
