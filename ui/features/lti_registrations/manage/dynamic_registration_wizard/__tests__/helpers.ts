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

import type {LtiPlacement} from '../../model/LtiPlacement'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'
import {ZLtiImsRegistrationId} from '../../model/lti_ims_registration/LtiImsRegistrationId'
import type {DynamicRegistrationWizardService} from '../DynamicRegistrationWizardService'
import type {Lti1p3RegistrationWizardService} from '../../lti_1p3_registration_form/Lti1p3RegistrationWizardService'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {ZAccountId} from '../../model/AccountId'
import type {LtiOverlay} from '../../model/LtiOverlay'
import {ZLtiOverlayId} from '../../model/ZLtiOverlayId'
import {ZUserId} from '../../model/UserId'

export const mockDynamicRegistrationWizardService = (
  mocked?: Partial<DynamicRegistrationWizardService>,
): DynamicRegistrationWizardService => ({
  fetchRegistrationToken: jest.fn(),
  deleteRegistration: jest.fn(),
  getRegistrationByUUID: jest.fn(),
  updateDeveloperKeyWorkflowState: jest.fn(),
  fetchLtiRegistration: jest.fn(),
  updateRegistration: jest.fn(),
  ...mocked,
})

export const mockLti1p3RegistrationWizardService = (
  mocked?: Partial<Lti1p3RegistrationWizardService>,
): Lti1p3RegistrationWizardService => ({
  createLtiRegistration: jest.fn(),
  updateLtiRegistration: jest.fn(),
  fetchLtiRegistration: jest.fn(),
  ...mocked,
})

export const mockToolConfiguration = (
  config?: Partial<InternalLtiConfiguration>,
): InternalLtiConfiguration => ({
  title: '',
  target_link_uri: '',
  oidc_initiation_url: '',
  custom_fields: {},
  scopes: [],
  placements: [],
  launch_settings: {},
  ...config,
})

export const mockRegistration = (
  reg?: Partial<LtiRegistrationWithConfiguration>,
  config?: Partial<InternalLtiConfiguration>,
): LtiRegistrationWithConfiguration => ({
  id: ZLtiRegistrationId.parse('1'),
  developer_key_id: ZDeveloperKeyId.parse('1'),
  overlay: null,
  created_at: new Date(),
  updated_at: new Date(),
  configuration: mockToolConfiguration(config),
  account_id: ZAccountId.parse('1'),
  icon_url: null,
  name: 'Test Registration',
  admin_nickname: 'Test Admin',
  workflow_state: 'active',
  vendor: 'canvas',
  internal_service: false,
  ims_registration_id: ZLtiImsRegistrationId.parse('1'),
  manual_configuration_id: null,
  ...reg,
})

export const mockOverlay = (overlay?: Partial<LtiOverlay>): LtiOverlay => ({
  id: ZLtiOverlayId.parse('1'),
  registration_id: ZLtiRegistrationId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  account_id: ZAccountId.parse('1'),
  created_at: new Date(),
  updated_at: new Date(),
  updated_by: {
    id: ZUserId.parse('1'),
    name: 'Foo',
    created_at: new Date(),
    short_name: 'Foo',
    sortable_name: 'Foo',
  },
  data: {
    description: 'Foo',
  },
  ...overlay,
})

export const mockConfigWithPlacements = (
  placements: LtiPlacement[],
): Partial<InternalLtiConfiguration> => {
  return {
    placements: placements.map(placement => ({
      placement,
      message_type: 'LtiResourceLinkRequest',
    })),
  }
}
