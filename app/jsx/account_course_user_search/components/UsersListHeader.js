/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {string, func, shape} from 'prop-types'
import {Tooltip} from '@instructure/ui-tooltip'
import {Table} from '@instructure/ui-table'
import {IconMiniArrowUpSolid, IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import preventDefault from 'compiled/fn/preventDefault'
import UsersListRow from './UsersListRow'

export default function UsersListHeader(props) {
  const {id, tipAsc, tipDesc, label, onUpdateFilters} = props
  const {sort, order, search_term, role_filter_id} = props.searchFilter
  const newOrder = (sort === id && order === 'asc') || (!sort && id === 'username') ? 'desc' : 'asc'

  return (
    <Table.ColHeader id={id} data-testid="UsersListHeader">
      <Tooltip tip={sort === id && order === 'asc' ? tipAsc : tipDesc}>
        <Button
          onClick={preventDefault(() => {
            onUpdateFilters({search_term, sort: id, order: newOrder, role_filter_id})
          })}
          variant="link"
          theme={{fontWeight: '700', mediumPadding: '0', mediumHeight: '1.5rem'}}
        >
          {label}
          {sort === id ? (
            order === 'asc' ? (
              <IconMiniArrowUpSolid />
            ) : (
              <IconMiniArrowDownSolid />
            )
          ) : (
            ''
          )}
        </Button>
      </Tooltip>
    </Table.ColHeader>
  )
}

UsersListHeader.propTypes = {
  id: string.isRequired,
  tipAsc: string.isRequired,
  tipDesc: string.isRequired,
  label: string.isRequired,
  onUpdateFilters: func.isRequired,
  searchFilter: shape({
    sort: string,
    order: string,
    search_term: string,
    fole_filter_id: string
  }).isRequired
}

UsersListHeader.displayName = 'ColHeader'
