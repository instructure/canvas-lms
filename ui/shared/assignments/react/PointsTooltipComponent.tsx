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
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('assignment_points_tooltip')

interface PointsTooltipComponentProps {
  shouldShow: boolean
}

export const PointsTooltipComponent: React.FC<PointsTooltipComponentProps> = ({shouldShow}) => {
  return (
    <span style={{display: shouldShow ? 'inline-block' : 'none'}}>
      <Tooltip
        renderTip={
          <React.Fragment>
            {I18n.t('Points earned here reflect participation and effort.')}
            <br />
            {I18n.t('Responses will not be graded for accuracy.')}
          </React.Fragment>
        }
        placement="end"
      >
        <IconInfoLine />
      </Tooltip>
    </span>
  )
}
