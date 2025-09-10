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

import React from 'react'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {isModuleUnlockAtDateInTheFuture} from '../utils/utils'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleHeaderUnlockAtProps {
  unlockAt: string | null
}

const ModuleHeaderUnlockAt: React.FC<ModuleHeaderUnlockAtProps> = ({unlockAt}) => {
  if (!unlockAt) return null
  if (!isModuleUnlockAtDateInTheFuture(unlockAt)) return null

  return (
    <Text size="x-small" wrap="break-word" color="secondary" data-testid="module-unlock-at-date">
      <FriendlyDatetime
        prefix={I18n.t('Will unlock')}
        prefixMobile={I18n.t('Unlocked')}
        format={I18n.t('#date.formats.date_at_time')}
        dateTime={unlockAt}
        alwaysUseSpecifiedFormat={true}
        includeScreenReaderContent={false}
      />
    </Text>
  )
}

export default ModuleHeaderUnlockAt
