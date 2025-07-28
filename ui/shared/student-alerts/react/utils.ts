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
import {useScope as createI18nScope} from '@canvas/i18n'
import {AccountRole, AlertUIMetadata} from './types'

const I18n = createI18nScope('alerts')

export const calculateUIMetadata = (accountRoles: AccountRole[]) => {
  const metadata: AlertUIMetadata = {
    POSSIBLE_RECIPIENTS: {
      ':student': I18n.t('Student'),
      ':teachers': I18n.t('Teacher'),
    },
    POSSIBLE_CRITERIA: {
      Interaction: {
        label: (count: number) =>
          I18n.t('A teacher has not interacted with the student for %{count} days.', {count}),
        option: I18n.t('No Teacher Interaction'),
        default_threshold: 7,
      },
      UngradedCount: {
        label: (count: number) =>
          I18n.t('More than %{count} submissions have not been graded.', {count}),
        option: I18n.t('Ungraded Submissions (Count)'),
        default_threshold: 3,
      },
      UngradedTimespan: {
        label: (count: number) =>
          I18n.t('A submission has been left ungraded for %{count} days.', {count}),
        option: I18n.t('Ungraded Submissions (Time)'),
        default_threshold: 7,
      },
    },
  }

  accountRoles.forEach(role => {
    metadata.POSSIBLE_RECIPIENTS[role.id] = role.label
  })

  return metadata
}
