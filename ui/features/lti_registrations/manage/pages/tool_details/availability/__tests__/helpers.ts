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

import {LtiContextControl, ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {LtiDeployment} from '../../../../model/LtiDeployment'
import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'

/**
 * Returns a mock LtiDeployment object with default values.
 * Any property can be overridden by passing it in the overrides parameter.
 */

export function mockDeployment(overrides: Partial<LtiDeployment> = {}): LtiDeployment {
  return {
    id: ZLtiDeploymentId.parse('default-id'),
    context_id: 'default-context-id',
    context_name: 'Default Context',
    context_type: 'Account',
    deployment_id: 'default-deployment-id',
    registration_id: ZLtiRegistrationId.parse('default-registration-id'),
    workflow_state: 'active',
    context_controls: [],
    ...overrides,
  }
} /**
 * Returns a mock LtiContextControl object with default values.
 * Any property can be overridden by passing it in the overrides parameter.
 */

export function mockContextControl(overrides: Partial<LtiContextControl> = {}): LtiContextControl {
  return {
    id: ZLtiContextControlId.parse('default-context-control-id'),
    registration_id: ZLtiRegistrationId.parse('default-registration-id'),
    deployment_id: 'default-deployment-id',
    account_id: null,
    course_id: null,
    available: true,
    path: '/default/path',
    display_path: ['default', 'path'],
    context_name: 'Default Context Name',
    depth: 0,
    workflow_state: 'active',
    created_at: new Date(),
    updated_at: new Date(),
    created_by: null,
    updated_by: null,
    child_control_count: 0,
    course_count: 0,
    subaccount_count: 0,
    ...overrides,
  }
}
