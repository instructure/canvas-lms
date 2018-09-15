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

import IconMiniArrowUp from '@instructure/ui-icons/lib/Solid/IconMiniArrowUp'
import IconMiniArrowDown from '@instructure/ui-icons/lib/Solid/IconMiniArrowDown'
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Link from '@instructure/ui-elements/lib/components/Link'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import React from 'react'
import {string} from 'prop-types'
import {pick} from 'lodash'
import preventDefault from 'compiled/fn/preventDefault'
import CoursesList from './CoursesList'

export default function CourseListHeader({sort, order, onChangeSort, id, label, tipDesc, tipAsc}) {
  return (
    <ApplyTheme theme={{[Link.theme]: {fontWeight: 'bold'}}}>
      <Tooltip
        as={Link}
        tip={sort === id && order === 'asc' ? tipAsc : tipDesc}
        onClick={preventDefault(() => onChangeSort(id))}
      >
        {label}
        {sort === id ? order === 'asc' ? <IconMiniArrowDown /> : <IconMiniArrowUp /> : ''}
      </Tooltip>
    </ApplyTheme>
  )
}

CourseListHeader.propTypes = {
  ...pick(CoursesList.propTypes, ['sort', 'order', 'onChangeSort']),
  id: string.isRequired,
  label: string.isRequired,
  tipDesc: string.isRequired,
  tipAsc: string.isRequired
}

CourseListHeader.defaultProps = pick(CoursesList.defaultProps, ['sort', 'order'])
