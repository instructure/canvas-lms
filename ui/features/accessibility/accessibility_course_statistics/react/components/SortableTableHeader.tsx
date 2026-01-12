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
import {IconMiniArrowUpSolid, IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'

export type SortOrder = 'asc' | 'desc'

interface SortableTableHeaderProps {
  id: string
  label: string
  tipDesc: string
  tipAsc: string
  currentSort: string
  currentOrder: SortOrder
  onChangeSort: (columnId: string) => void
}

export const SortableTableHeader: React.FC<SortableTableHeaderProps> = ({
  id,
  label,
  tipDesc,
  tipAsc,
  currentSort,
  currentOrder,
  onChangeSort,
}) => {
  const isCurrentSort = currentSort === id
  const SortIcon = currentOrder === 'asc' ? IconMiniArrowUpSolid : IconMiniArrowDownSolid
  const tooltipText = isCurrentSort && currentOrder === 'asc' ? tipAsc : tipDesc

  const handleClick = (event: any) => {
    event.preventDefault()
    onChangeSort(id)
  }

  return (
    <Tooltip renderTip={tooltipText}>
      <Link
        isWithinText={false}
        as="button"
        renderIcon={isCurrentSort ? <SortIcon /> : undefined}
        iconPlacement="end"
        onClick={handleClick}
      >
        <Text weight="bold">{label}</Text>
      </Link>
    </Tooltip>
  )
}
