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

import {useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {windowConfirm} from '@canvas/util/globalUtils'

const I18n = createI18nScope('discovery_page')

/**
 * Hook to handle exit confirmation when there are unsaved changes.
 * Shows a confirmation dialog if isDirty is true.
 *
 * @param isDirty Whether there are unsaved changes
 * @returns A function to call when attempting to close/exit
 */
export function useExitConfirmation(isDirty: boolean) {
  return useCallback(
    (onConfirmed: () => void) => {
      if (!isDirty) {
        onConfirmed()
        return
      }

      const confirmed = windowConfirm(
        I18n.t('You have unsaved changes. Are you sure you want to close?'),
      )

      if (confirmed) {
        onConfirmed()
      }
    },
    [isDirty],
  )
}
