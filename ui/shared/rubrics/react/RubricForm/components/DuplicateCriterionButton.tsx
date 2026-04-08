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

import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconDuplicateLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('rubrics-criteria-row')

type DuplicateCriterionButtonProps = {
  disabled: boolean
  onClick: () => void
}

export const DuplicateCriterionButton = ({disabled, onClick}: DuplicateCriterionButtonProps) => {
  const label = I18n.t('Duplicate Criterion')

  return (
    <Tooltip renderTip={label}>
      <IconButton
        withBackground={false}
        withBorder={false}
        screenReaderLabel={label}
        onClick={onClick}
        size="small"
        themeOverride={{smallHeight: '18px'}}
        data-testid="rubric-criteria-row-duplicate-button"
        disabled={disabled}
      >
        <IconDuplicateLine />
      </IconButton>
    </Tooltip>
  )
}
