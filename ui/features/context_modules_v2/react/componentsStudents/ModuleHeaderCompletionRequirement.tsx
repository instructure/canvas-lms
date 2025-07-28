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

import React from 'react'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Pill} from '@instructure/ui-pill'
import {IconCheckLine} from '@instructure/ui-icons'

const I18n = createI18nScope('context_modules_v2')

type Props = {
  requirementCount?: number
  completed?: boolean
}

const getPillText = (requirementCount?: number, completed?: boolean) => {
  if (completed) {
    return requirementCount ? I18n.t('Completed 1 item') : I18n.t('Completed all items')
  }

  return requirementCount ? I18n.t('Complete 1 item') : I18n.t('Complete all items')
}

export const getPillColor = (completed?: boolean) => {
  if (completed) {
    return 'success'
  }
  return 'info'
}

export const ModuleHeaderCompletionRequirement = ({requirementCount, completed}: Props) => {
  return (
    <Pill
      color={getPillColor(completed)}
      data-testid="module-completion-requirement"
      renderIcon={
        completed ? <IconCheckLine data-testid="module-header-completion-requirement-icon" /> : null
      }
    >
      <Text size="x-small">{getPillText(requirementCount, completed)}</Text>
    </Pill>
  )
}
