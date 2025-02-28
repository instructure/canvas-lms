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

const I18n = createI18nScope('course_people')

export type RosterTableHeaderProps = {
  allSelected: boolean
  someSelected: boolean
  sortBy: string
  direction: 'ascending' | 'descending' | 'none'
  handleSelectAll: (checked: boolean) => void
  handleSort: (event: SyntheticEvent<Element, Event>, {id}: {id: string}) => void
}

const RosterTableHeader: FC<RosterTableHeaderProps> = ({
  allSelected,
  someSelected,
  sortBy,
  direction,
  handleSelectAll,
  handleSort
}) => {
  const {
    canViewLoginIdColumn,
    canViewSisIdColumn,
    canReadReports,
    hideSectionsOnCourseUsersPage,
    canManageDifferentiationTags,
    allowAssignToDifferentiationTags
  } = useCoursePeopleContext()

  const CustomColHeader: FC<{
    id: string
    name: string
    width?: string
  }> = ({
    id,
    name,
    width
  }) => (
    <Table.ColHeader
      id={id}
      width={width}
      onRequestSort={handleSort}
      sortDirection={id === sortBy ? direction : 'none'}
      data-testid={`header-${id}`}
    >
      {name}
    </Table.ColHeader>
  )

  return (
    <Table.Head
      renderSortLabel={
        <ScreenReaderContent>
          {I18n.t('Sort by')}
        </ScreenReaderContent>
      }
    >
      <Table.Row>
        {allowAssignToDifferentiationTags && canManageDifferentiationTags
          ? (
              <Table.ColHeader
                id="select"
                width="36px"
              >
                <Checkbox
                  label={
                    <ScreenReaderContent>
                      {I18n.t('Select all')}
                    </ScreenReaderContent>
                  }
                  onChange={() => handleSelectAll(allSelected)}
                  checked={allSelected}
                  indeterminate={someSelected}
                  data-testid="header-select-all"
                />
              </Table.ColHeader>
            )
          : <></>
        }
        <CustomColHeader
          id="name"
          name={I18n.t("Name")}
        />
        {canViewLoginIdColumn
          ? (
              <CustomColHeader
                id="loginID"
                name= {I18n.t("Login ID")}
                width="13%"
              />
            )
          : <></>
        }
        {canViewSisIdColumn
          ? (
              <CustomColHeader
                id="sisID"
                name={I18n.t("SIS ID")}
                width="9%"
              />
            )
          : <></>
        }
        {!hideSectionsOnCourseUsersPage
          ? (
            <CustomColHeader
              id="section"
              name={I18n.t("Section")}
              width="12%"
            />
          )
          : <></>
        }
        <CustomColHeader
          id="role"
          name={I18n.t("Role")}
          width="8%"
        />
        {canReadReports
          ? (
              <CustomColHeader
                id="lastActivity"
                name={I18n.t("Last Activity")}
                width="13%"
              />
            )
          : <></>
        }
        {canReadReports
          ? (
              <CustomColHeader
                id="totalActivity"
                name={I18n.t("Total Activity")}
                width="13%"
              />
            )
          : <></>
        } 
        <Table.ColHeader
          id="userOptionsMenu"
          width="36px"
          data-testid="header-admin-links"
        >
          <ScreenReaderContent>
            {I18n.t('Administrative Links')}
          </ScreenReaderContent>
        </Table.ColHeader>
      </Table.Row>
    </Table.Head>
  )
}

export default RosterTableHeader
