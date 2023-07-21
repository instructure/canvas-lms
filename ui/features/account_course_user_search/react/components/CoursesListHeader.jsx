/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {IconMiniArrowUpSolid, IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import React from 'react'
import {string, func} from 'prop-types'
import preventDefault from '@canvas/util/preventDefault'

export default function CourseListHeader({sort, order, onChangeSort, id, label, tipDesc, tipAsc}) {
  const SortIcon = order === 'asc' ? IconMiniArrowUpSolid : IconMiniArrowDownSolid
  return (
    <Tooltip renderTip={sort === id && order === 'asc' ? tipAsc : tipDesc}>
      <Link
        isWithinText={false}
        as="button"
        renderIcon={sort === id ? <SortIcon /> : undefined}
        iconPlacement="end"
        onClick={preventDefault(() => onChangeSort(id))}
      >
        <Text weight="bold">{label}</Text>
      </Link>
    </Tooltip>
  )
}

CourseListHeader.propTypes = {
  sort: string,
  order: string,
  onChangeSort: func.isRequired,
  id: string.isRequired,
  label: string.isRequired,
  tipDesc: string.isRequired,
  tipAsc: string.isRequired,
}

CourseListHeader.defaultProps = {
  sort: 'sis_course_id',
  order: 'asc',
}
