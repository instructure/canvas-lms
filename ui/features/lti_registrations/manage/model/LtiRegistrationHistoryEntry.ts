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

import {z} from 'zod'
import {ZAccountId} from './AccountId'
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUser} from './User'
import {ZInternalLtiConfiguration} from './internal_lti_configuration/InternalLtiConfiguration'
import {ZLtiRegistration} from './LtiRegistration'
import {ZLtiContextControl, ZLtiContextControlId} from './LtiContextControl'
import {ZDeveloperKey} from './developer_key/DeveloperKey'
import {ZLtiOverlay} from './LtiOverlay'
import {ZLtiConfigurationOverlay} from './internal_lti_configuration/LtiConfigurationOverlay'

export const ZLtiRegistrationHistoryEntryId = z.string().brand('ZLtiRegistrationHistoryEntryId')

const DevKeyAttributesMask = {
  email: true,
  user_name: true,
  name: true,
  redirect_uri: true,
  redirect_uris: true,
  icon_url: true,
  vendor_code: true,
  public_jwk: true,
  oidc_initiation_url: true,
  public_jwk_url: true,
  scopes: true,
} as const

export const ZDeveloperKeyAttributes = ZDeveloperKey.pick(DevKeyAttributesMask)

export type DeveloperKeyTrackedAttributes = z.infer<typeof ZDeveloperKeyAttributes>

const RegistrationAttributesMask = {
  admin_nickname: true,
  name: true,
  vendor: true,
  workflow_state: true,
  description: true,
} as const

export const ZLtiRegistrationAttributes = ZLtiRegistration.pick(RegistrationAttributesMask)

export type LtiRegistrationTrackedAttributes = z.infer<typeof ZLtiRegistrationAttributes>

export const ContextControlAttributesMask = {
  id: true,
  account_id: true,
  course_id: true,
  deployment_id: true,
  available: true,
  workflow_state: true,
} as const

export const ZLtiContextControlAttributes = ZLtiContextControl.pick(ContextControlAttributesMask)

export type LtiContextControlTrackedAttributes = z.infer<typeof ZLtiContextControlAttributes>

export const ZConfigurationSnapshot = z.object({
  internal_config: ZInternalLtiConfiguration,
  developer_key: ZDeveloperKeyAttributes,
  registration: ZLtiRegistrationAttributes,
  overlaid_internal_config: ZInternalLtiConfiguration,
  // Overlay data can be null if no overlay exists yet, which is common
  // for brand-new registrations.
  overlay: ZLtiConfigurationOverlay.nullish(),
})

const ZBaseLtiRegistrationHistoryEntry = z.object({
  id: ZLtiRegistrationHistoryEntryId,
  root_account_id: ZAccountId,
  lti_registration_id: ZLtiRegistrationId,
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  // We don't actually use the diff anymore, as dealing with Hashdiff's paths
  // was *very* annoying.
  diff: z.unknown(),
  update_type: z.enum([
    'manual_edit',
    'registration_update',
    'control_edit',
    'bulk_control_create',
  ]),
  comment: z.string().nullable(),
  created_by: z.union([ZUser, z.literal('Instructure')]),
})

export const ZHistoryEntryForAvailabilityChange = z.intersection(
  ZBaseLtiRegistrationHistoryEntry,
  z.object({
    update_type: z.union([z.literal('control_edit'), z.literal('bulk_control_create')]),
    old_context_controls: z.record(ZLtiContextControlId, ZLtiContextControlAttributes),
    new_context_controls: z.record(ZLtiContextControlId, ZLtiContextControlAttributes),
  }),
)

export const ZHistoryEntryForConfigChange = z.intersection(
  ZBaseLtiRegistrationHistoryEntry,
  z.object({
    update_type: z.union([z.literal('manual_edit'), z.literal('registration_update')]),
    old_configuration: ZConfigurationSnapshot,
    new_configuration: ZConfigurationSnapshot,
  }),
)

export type AvailabilityChangeHistoryEntry = z.infer<typeof ZHistoryEntryForAvailabilityChange>

export type ConfigChangeHistoryEntry = z.infer<typeof ZHistoryEntryForConfigChange>

export const isEntryForAvailabilityChange = (
  entry: LtiRegistrationHistoryEntry,
): entry is AvailabilityChangeHistoryEntry => {
  return entry.update_type === 'control_edit' || entry.update_type === 'bulk_control_create'
}

export const isEntryForConfigChange = (
  entry: LtiRegistrationHistoryEntry,
): entry is ConfigChangeHistoryEntry => {
  return entry.update_type === 'manual_edit' || entry.update_type === 'registration_update'
}

/**
 * @see The Lti::RegistrationHistoryEntry Rails model and its associated serializer.
 */
export const ZLtiRegistrationHistoryEntry = z.union([
  ZHistoryEntryForAvailabilityChange,
  ZHistoryEntryForConfigChange,
])

export type LtiRegistrationHistoryEntry = z.infer<typeof ZLtiRegistrationHistoryEntry>
