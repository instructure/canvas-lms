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

import {z} from 'zod'
import {ZAccountId} from './AccountId'
import {ZDeveloperKeyId} from './developer_key/DeveloperKeyId'
import {ZInternalLtiConfiguration} from './internal_lti_configuration/InternalLtiConfiguration'
import {ZInternalBaseLaunchSettings} from './internal_lti_configuration/InternalBaseLaunchSettings'
import {ZLtiImsRegistrationId} from './lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from './lti_tool_configuration/LtiToolConfigurationId'
import {ZLtiOverlay, ZLtiOverlayWithVersions} from './LtiOverlay'
import {ZLtiRegistrationAccountBinding} from './LtiRegistrationAccountBinding'
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUser} from './User'
import {ZLtiOverlayVersion} from './LtiOverlayVersion'
import {ZLtiPrivacyLevel} from './LtiPrivacyLevel'
import {ZInternalPlacementConfiguration} from './internal_lti_configuration/placement_configuration/InternalPlacementConfiguration'

export const ZLtiRegistration = z.object({
  id: ZLtiRegistrationId,
  account_id: ZAccountId,
  icon_url: z.string().nullable(),
  inherited: z.boolean().optional(),
  name: z.string(),
  admin_nickname: z.string().nullable(),
  workflow_state: z.string(),
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  created_by: z.union([ZUser, z.literal('Instructure')]).optional(),
  updated_by: z.union([ZUser, z.literal('Instructure')]).optional(),
  vendor: z.string().nullable(),
  internal_service: z.boolean(),
  developer_key_id: ZDeveloperKeyId.nullable(),
  ims_registration_id: ZLtiImsRegistrationId.nullable(),
  manual_configuration_id: ZLtiToolConfigurationId.nullable(),
  account_binding: ZLtiRegistrationAccountBinding.nullable().optional(),
  overlay: ZLtiOverlay.nullable().optional(),
})

export type LtiRegistration = z.infer<typeof ZLtiRegistration>

export const ZLtiRegistrationWithConfiguration = ZLtiRegistration.extend({
  configuration: ZInternalLtiConfiguration,
})

export type LtiRegistrationWithConfiguration = z.infer<typeof ZLtiRegistrationWithConfiguration>

export const ZLtiRegistrationWithAllInformation = ZLtiRegistrationWithConfiguration.extend({
  overlaid_configuration: ZInternalLtiConfiguration,
  overlay: ZLtiOverlayWithVersions.nullable().optional(),
})

export type LtiRegistrationWithAllInformation = z.infer<typeof ZLtiRegistrationWithAllInformation>

export const ZLtiLegacyConfiguration = ZInternalLtiConfiguration.omit({
  launch_settings: true,
  domain: true,
  placements: true,
  redirect_uris: true,
  tool_id: true,
  privacy_level: true,
}).extend({
  custom_fields: z.record(z.string()).optional(),
  extensions: z.array(
    z.object({
      tool_id: z.string().nullable().optional(),
      domain: z.string().nullable().optional(),
      privacy_level: ZLtiPrivacyLevel.nullable().optional(),
      platform: z.literal('canvas.instructure.com'),
      settings: z
        .object({
          placements: z.array(ZInternalPlacementConfiguration),
        })
        .merge(ZInternalBaseLaunchSettings),
    }),
  ),
})

export const ZLtiRegistrationWithLegacyConfiguration = ZLtiRegistration.extend({
  overlaid_legacy_configuration: ZLtiLegacyConfiguration,
})

export type LtiRegistrationWithLegacyConfiguration = z.infer<
  typeof ZLtiRegistrationWithLegacyConfiguration
>

export const isForcedOn = (reg: LtiRegistration) =>
  reg.inherited &&
  reg.account_binding?.account_id === reg.account_id &&
  reg.account_binding?.workflow_state == 'on'
