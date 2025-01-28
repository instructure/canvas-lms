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
import {Table} from '@instructure/ui-table'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import UserLink from './UserLink'
import UserLastActivity from './UserLastActivity'
import UserRole from './UserRole'
import {totalActivity} from '../../../util/utils'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {User} from '../../types.d'

const I18n = createI18nScope('course_people')

type RosterTableRowProps = {
  user: User
  isSelected: boolean
  handleSelectRow: (selected: boolean, id: string) => void
}

const RosterTableRow: React.FC<RosterTableRowProps> = ({
  user,
  isSelected,
  handleSelectRow
}) => {
  const {
    id: uid,
    short_name: name,
    login_id: loginId,
    sis_user_id: sisUserId,
    avatar_url: avatarUrl,
    enrollments,
    pronouns
  } = user
  const {
    courseRootUrl,
    canViewLoginIdColumn,
    canViewSisIdColumn,
    canReadReports,
    hideSectionsOnCourseUsersPage,
    canManageDifferentiationTags,
    allowAssignToDifferentiationTags
  } = useCoursePeopleContext()
  const userLink = `${courseRootUrl}/users/${uid}`

  const renderSections = () => (enrollments || []).map(e => (
    <View as="div" key={`enrollment-${e.id}`}>{e.name}</View>)
  )

  return (
    <Table.Row data-testid={`table-row-${uid}`}>
      {allowAssignToDifferentiationTags && canManageDifferentiationTags
        ? (
            <Table.RowHeader>
              <Checkbox
                label={
                  <ScreenReaderContent>
                    {I18n.t('Select %{name}', {name})}
                  </ScreenReaderContent>
                }
                onChange={() => handleSelectRow(isSelected, uid)}
                checked={isSelected}
                data-testid={`select-user-${uid}`}
              />
            </Table.RowHeader>
          )
        : <></>
      }
      <Table.Cell>
        <UserLink
          uid={uid}
          userUrl={userLink}
          name={name}
          pronouns={pronouns}
          avatarUrl={avatarUrl}
          avatarName={name}
          enrollments={enrollments}
        />
      </Table.Cell>
      {canViewLoginIdColumn
        ? (
            <Table.Cell data-testid={`login-id-user-${uid}`}>
              <Text>{loginId}</Text>
            </Table.Cell>
          )
        : <></>
      }
      {canViewSisIdColumn
        ? (
            <Table.Cell data-testid={`sis-id-user-${uid}`}>
              <Text>{sisUserId}</Text>
            </Table.Cell>
          )
        : <></>
      }
      {!hideSectionsOnCourseUsersPage
        ? (
            <Table.Cell data-testid={`sections-user-${uid}`}>
              {renderSections()}
            </Table.Cell>
          )
        : <></>
      }  
      <Table.Cell>
        <UserRole enrollments={enrollments} />
      </Table.Cell>
      {canReadReports
        ? (
            <Table.Cell data-testid={`last-activity-user-${uid}`}>
              <UserLastActivity enrollments={enrollments} />
            </Table.Cell>
          )
        : <></>
      }
      {canReadReports
        ? (
            <Table.Cell data-testid={`total-activity-user-${uid}`}>
              <View as="div">
                {totalActivity(enrollments)}
              </View>
            </Table.Cell>
          )
        : <></>
      }
      <Table.Cell textAlign="end" data-testid={`options-menu-user-${uid}`}>
        <IconButton
          size="small"
          renderIcon={<IconMoreLine />}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Manage %{name}', {name})}
        />
      </Table.Cell>
    </Table.Row>
  )
}

export default RosterTableRow
