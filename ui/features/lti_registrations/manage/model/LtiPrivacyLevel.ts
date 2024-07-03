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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

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
 * Returns true if the given value is a valid LTI privacy level.
 * @param setting
 * @returns
 */
export const isLtiPrivacyLevel = (setting: unknown): setting is LtiPrivacyLevel =>
  Object.values(LtiPrivacyLevels).includes(setting as LtiPrivacyLevel)

const LtiPrivacyLevelTranslations: Record<LtiPrivacyLevel, string> = {
  [LtiPrivacyLevels.Public]: I18n.t('All user data'),
  [LtiPrivacyLevels.NameOnly]: I18n.t("User's name only"),
  [LtiPrivacyLevels.EmailOnly]: I18n.t("User's email only"),
  [LtiPrivacyLevels.Anonymous]: I18n.t('None (Anonymized)'),
}

const LtiPrivacyLevelDescriptions: Record<LtiPrivacyLevel, string> = {
  [LtiPrivacyLevels.Public]: I18n.t(
    'Includes: Canvas ID, Name, First Name, Last Name, SIS ID, Avatar, and Email Address'
  ),
  [LtiPrivacyLevels.NameOnly]: I18n.t(
    'Includes: Canvas ID, Name, First Name, Last Name, SIS ID, and Avatar'
  ),
  [LtiPrivacyLevels.EmailOnly]: I18n.t('Includes: Canvas ID and Email Address'),
  [LtiPrivacyLevels.Anonymous]: I18n.t('Includes: Canvas ID'),
}

/**
 * Returns the translation for the given LTI privacy level.
 * @param level
 * @returns string that contains a human readable translation
 */
export const i18nLtiPrivacyLevel = (level: LtiPrivacyLevel) => LtiPrivacyLevelTranslations[level]

/**
 * Returns the description for the given LTI privacy level.
 * @param level
 * @returns string that contains a human readable description of what information a privacy level includes
 */
export const i18nLtiPrivacyLevelDescription = (level: LtiPrivacyLevel) =>
  LtiPrivacyLevelDescriptions[level]

/**
 * Identifier for an LTI privacy setting.
 */
export type LtiPrivacyLevel = z.infer<typeof ZLtiPrivacyLevel>
