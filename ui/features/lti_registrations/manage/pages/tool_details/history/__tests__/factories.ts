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
import {ZAccountId} from '../../../../model/AccountId'
import {InternalLtiConfiguration} from '../../../../model/internal_lti_configuration/InternalLtiConfiguration'
import {
  AvailabilityChangeHistoryEntry,
  ConfigChangeHistoryEntry,
  ZLtiRegistrationHistoryEntryId,
} from '../../../../model/LtiRegistrationHistoryEntry'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {mockToolConfiguration} from '../../../../dynamic_registration_wizard/__tests__/helpers'
import {LtiDeployment} from '../../../../model/LtiDeployment'
import {mockDeployment} from '../../../manage/__tests__/helpers'

export const createMockConfigEntry = (
  oldConfig: Partial<InternalLtiConfiguration>,
  newConfig: Partial<InternalLtiConfiguration>,
): ConfigChangeHistoryEntry => ({
  id: ZLtiRegistrationHistoryEntryId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date(),
  updated_at: new Date(),
  diff: {},
  update_type: 'manual_edit',
  comment: null,
  created_by: 'Instructure',
  old_configuration: {
    internal_config: mockToolConfiguration(oldConfig),
    developer_key: {
      email: null,
      name: 'Test Key',
      redirect_uri: null,
      redirect_uris: [],
      icon_url: null,
      vendor_code: null,
      public_jwk: null,
      public_jwk_url: null,
      scopes: [],
    },
    registration: {
      admin_nickname: null,
      name: 'Test Tool',
      vendor: 'Test Vendor',
      workflow_state: 'active',
      description: null,
    },
    overlay: {},
    overlaid_internal_config: mockToolConfiguration(oldConfig),
  },
  new_configuration: {
    internal_config: mockToolConfiguration(newConfig),
    developer_key: {
      email: null,
      name: 'Test Key',
      redirect_uri: null,
      redirect_uris: [],
      icon_url: null,
      vendor_code: null,
      public_jwk: null,
      public_jwk_url: null,
      scopes: [],
    },
    registration: {
      admin_nickname: null,
      name: 'Test Tool',
      vendor: 'Test Vendor',
      workflow_state: 'active',
      description: null,
    },
    overlay: {},
    overlaid_internal_config: mockToolConfiguration(newConfig),
  },
})

// Helper function to create mock availability change entries
// Accepts deployment structures and automatically converts to branded types
export const createMockAvailabilityEntry = (
  oldDeployments: Array<Partial<LtiDeployment>>,
  newDeployments: Array<Partial<LtiDeployment>>,
): AvailabilityChangeHistoryEntry => {
  return {
    id: ZLtiRegistrationHistoryEntryId.parse('1'),
    root_account_id: ZAccountId.parse('1'),
    lti_registration_id: ZLtiRegistrationId.parse('1'),
    created_at: new Date(),
    updated_at: new Date(),
    diff: {},
    update_type: 'control_edit',
    comment: null,
    created_by: 'Instructure',
    old_controls_by_deployment: oldDeployments.map(mockDeployment),
    new_controls_by_deployment: newDeployments.map(mockDeployment),
  }
}
