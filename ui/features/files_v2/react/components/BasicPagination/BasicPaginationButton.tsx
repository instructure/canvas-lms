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

import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndSolid, IconArrowOpenStartSolid} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

export type BasicPaginationButtonProps = {
  variant: 'prev' | 'next'
  onClick: () => void
  screenReaderLabel: string
  disabled: boolean
}

export const BasicPaginationButton = (props: BasicPaginationButtonProps) => {
  const renderIcon =
    props.variant === 'prev' ? <IconArrowOpenStartSolid /> : <IconArrowOpenEndSolid />
  return (
    <Tooltip renderTip={props.screenReaderLabel}>
      <IconButton
        screenReaderLabel={props.screenReaderLabel}
        renderIcon={renderIcon}
        disabled={props.disabled}
        onClick={props.onClick}
        size="small"
        withBackground={false}
        withBorder={false}
      />
    </Tooltip>
  )
}
