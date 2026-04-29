/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {forwardRef} from 'react'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'

interface DismissibleTagWithTooltipProps {
  text: string
  accessibleLabel: string
  onClick: () => void
  tooltipThreshold?: number
}

const DismissibleTagWithTooltip = forwardRef<Tag, DismissibleTagWithTooltipProps>(
  ({text, accessibleLabel, onClick, tooltipThreshold = 20}, ref) => {
    const shouldShowTooltip = text.length >= tooltipThreshold

    return (
      <Tooltip renderTip={text} preventTooltip={!shouldShowTooltip}>
        <Tag
          ref={ref}
          text={<AccessibleContent alt={accessibleLabel}>{text}</AccessibleContent>}
          dismissible={true}
          onClick={onClick}
        />
      </Tooltip>
    )
  },
)

DismissibleTagWithTooltip.displayName = 'DismissibleTagWithTooltip'

export default DismissibleTagWithTooltip
