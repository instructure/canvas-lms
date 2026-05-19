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

import React from 'react'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('AssignmentListItemView')

interface ModuleTooltipProps {
  modules: string[]
}

export default function ModuleTooltip({modules}: ModuleTooltipProps) {
  return (
    <Tooltip renderTip={modules.join(', ')} placement="top" on={['hover', 'focus']}>
      <Link as="button" isWithinText={false}>
        {I18n.t('Multiple Modules')}
      </Link>
    </Tooltip>
  )
}
