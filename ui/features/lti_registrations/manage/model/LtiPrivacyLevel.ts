/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import * as z from 'zod'

/**
 * The set of Privacy Levels that a tool can be configured with.
 */
export const LtiPrivacyLevels = {
  Anonymous: 'anonymous',
  NameOnly: 'name_only',
  EmailOnly: 'email_only',
  Public: 'public',
} as const

export const AllLtiPrivacyLevels = [
  LtiPrivacyLevels.Anonymous,
  LtiPrivacyLevels.NameOnly,
  LtiPrivacyLevels.EmailOnly,
  LtiPrivacyLevels.Public,
] as const

export const ZLtiPrivacyLevel = z.enum(AllLtiPrivacyLevels)

/**
 * The default privacy level for an LTI tool, if one isn't provided.
 */
export const DefaultLtiPrivacyLevel = LtiPrivacyLevels.Anonymous

/**
 * Returns true if the given value is a valid LTI privacy level.
 * @param setting
 * @returns
 */
export const isLtiPrivacyLevel = (setting: unknown): setting is LtiPrivacyLevel =>
  Object.values(LtiPrivacyLevels).includes(setting as LtiPrivacyLevel)

/**
 * Identifier for an LTI privacy setting.
 */
export type LtiPrivacyLevel = z.infer<typeof ZLtiPrivacyLevel>
