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

import React, {type FC, type SyntheticEvent} from 'react'
import {Table} from '@instructure/ui-table'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ASC, ASCENDING, DESCENDING} from '../../../util/constants'
import {SortField, SortDirection, TableHeaderSortDirection} from '../../../types'

const I18n = createI18nScope('course_people')

export type RosterTableHeaderProps = {
  allSelected: boolean
  someSelected: boolean
  sortField: SortField
  sortDirection: SortDirection
  handleSelectAll: (checked: boolean) => void
  handleSort: (event: SyntheticEvent<Element, Event>, {id}: {id: string}) => void
}

const RosterTableHeader: FC<RosterTableHeaderProps> = ({
  allSelected,
  someSelected,
  sortField,
  sortDirection,
  handleSelectAll,
  handleSort,
}) => {
  const {
    canViewLoginIdColumn,
    canViewSisIdColumn,
    canReadReports,
    hideSectionsOnCourseUsersPage,
    canManageDifferentiationTags,
    allowAssignToDifferentiationTags,
  } = useCoursePeopleContext()

  const CustomColHeader: FC<{
    id: string
    name: string
    width?: string
  }> = ({id, name, width}) => {
    let sortOrder: TableHeaderSortDirection = 'none'
    if (id === sortField) {
      sortOrder = sortDirection === ASC ? ASCENDING : DESCENDING
    }

    return (
      <Table.ColHeader
        id={id}
        width={width}
        onRequestSort={handleSort}
        sortDirection={sortOrder}
        data-testid={`header-${id}`}
      >
        {name}
      </Table.ColHeader>
    )
  }

  // Create an array of header columns based on conditions
  const headerColumns: JSX.Element[] = []

  if (allowAssignToDifferentiationTags && canManageDifferentiationTags) {
    headerColumns.push(
      <Table.ColHeader key="select" id="select" width="36px">
        <Checkbox
          label={<ScreenReaderContent>{I18n.t('Select all')}</ScreenReaderContent>}
          onChange={() => handleSelectAll(allSelected)}
          checked={allSelected}
          indeterminate={someSelected}
          data-testid="header-select-all"
        />
      </Table.ColHeader>,
    )
  }

  headerColumns.push(<CustomColHeader key="name" id="name" name={I18n.t('Name')} />)

  if (canViewLoginIdColumn) {
    headerColumns.push(
      <CustomColHeader key="login_id" id="login_id" name={I18n.t('Login ID')} width="13%" />,
    )
  }

  if (canViewSisIdColumn) {
    headerColumns.push(
      <CustomColHeader key="sis_id" id="sis_id" name={I18n.t('SIS ID')} width="9%" />,
    )
  }

  if (!hideSectionsOnCourseUsersPage) {
    headerColumns.push(
      <CustomColHeader key="section_name" id="section_name" name={I18n.t('Section')} width="12%" />,
    )
  }

  headerColumns.push(<CustomColHeader key="role" id="role" name={I18n.t('Role')} width="8%" />)

  if (canReadReports) {
    headerColumns.push(
      <CustomColHeader
        key="last_activity_at"
        id="last_activity_at"
        name={I18n.t('Last Activity')}
        width="13%"
      />,
    )
    headerColumns.push(
      <CustomColHeader
        key="total_activity_time"
        id="total_activity_time"
        name={I18n.t('Total Activity')}
        width="13%"
      />,
    )
  }

  headerColumns.push(
    <Table.ColHeader
      key="userOptionsMenu"
      id="userOptionsMenu"
      width="36px"
      data-testid="header-admin-links"
    >
      <ScreenReaderContent>{I18n.t('Administrative Links')}</ScreenReaderContent>
    </Table.ColHeader>,
  )

  return (
    <Table.Head>
      <Table.Row>{headerColumns}</Table.Row>
    </Table.Head>
  )
}

export default RosterTableHeader
