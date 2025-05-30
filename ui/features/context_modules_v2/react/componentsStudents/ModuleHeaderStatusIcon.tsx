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
import {IconPublishSolid, IconEmptyLine, IconLockSolid} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleProgression} from '../utils/types'

export interface ModuleHeaderStatusIconProps {
  progression: ModuleProgression
}

const I18n = createI18nScope('context_modules_v2')

const ModuleHeaderStatusIcon: React.FC<ModuleHeaderStatusIconProps> = ({progression}) => {
  if (!progression) return null

  const {completed, locked, started} = progression

  let icon = null
  let screenReaderMessage = ''

  if (locked) {
    icon = (
      <IconLockSolid data-testid="module-header-status-icon-lock" color="primary" size="small" />
    )
    screenReaderMessage = I18n.t('Locked')
  } else if (completed) {
    icon = (
      <IconPublishSolid
        data-testid="module-header-status-icon-success"
        color="success"
        size="small"
      />
    )
    screenReaderMessage = I18n.t('Completed')
  } else if (started) {
    icon = (
      <IconEmptyLine data-testid="module-header-status-icon-empty" color="primary" size="small" />
    )
    screenReaderMessage = I18n.t('In Progress')
  } else {
    return null
  }

  return (
    <Tooltip renderTip={screenReaderMessage} on={['hover', 'focus']}>
      <span>{icon}</span>
    </Tooltip>
  )
}

export default ModuleHeaderStatusIcon
