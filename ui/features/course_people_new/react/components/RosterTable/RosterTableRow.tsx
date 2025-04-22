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
import UserLink from './UserLink'
import UserMenu from './UserMenu'
import UserLastActivity from './UserLastActivity'
import UserRole from './UserRole'
import {totalActivity} from '../../../util/utils'
import {
  TEACHER_ENROLLMENT,
  TA_ENROLLMENT,
  DESIGNER_ENROLLMENT,
  OBSERVER_ENROLLMENT,
} from '../../../util/constants'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {User} from '../../../types'

const I18n = createI18nScope('course_people')

export type RosterTableRowProps = {
  user: User
  isSelected: boolean
  handleSelectRow: (selected: boolean, id: string) => void
}

const RosterTableRow: React.FC<RosterTableRowProps> = ({user, isSelected, handleSelectRow}) => {
  const {_id: uid, name, loginId, sisId, avatarUrl, customLinks, pronouns} = user

  const {
    canViewLoginIdColumn,
    canViewSisIdColumn,
    canReadReports,
    hideSectionsOnCourseUsersPage,
    canManageDifferentiationTags,
    canAllowCourseAdminActions,
    canManageStudents,
    allowAssignToDifferentiationTags,
  } = useCoursePeopleContext()

  const enrollments = user?.enrollments || []
  const htmlUrl = enrollments[0]?.htmlUrl
  const canRemoveUsers = enrollments.every(e => e.canBeRemoved)
  const canManage = enrollments.some(e =>
    [TEACHER_ENROLLMENT, TA_ENROLLMENT, DESIGNER_ENROLLMENT].includes(e.type),
  )
    ? canAllowCourseAdminActions
    : enrollments.some(e => e.type === OBSERVER_ENROLLMENT)
      ? canAllowCourseAdminActions || canManageStudents
      : canManageStudents

  const onResendInvitationHandler = () => {}
  const onLinkStudentsHandler = () => {}
  const onEditSectionsHandler = () => {}
  const onEditRolesHandler = () => {}
  const onReactivateUserHandler = () => {}
  const onDeactivateUserHandler = () => {}
  const onRemoveUserHandler = () => {}
  const onCustomLinkSelectHandler = () => {}

  const renderSections = () =>
    enrollments.map(e => (
      <View as="div" key={`enrollment-${e._id}`}>
        {e.section.name}
      </View>
    ))

  return (
    <Table.Row data-testid={`table-row-${uid}`}>
      {allowAssignToDifferentiationTags && canManageDifferentiationTags ? (
        <Table.RowHeader>
          <Checkbox
            label={<ScreenReaderContent>{I18n.t('Select %{name}', {name})}</ScreenReaderContent>}
            onChange={() => handleSelectRow(isSelected, uid)}
            checked={isSelected}
            data-testid={`select-user-${uid}`}
          />
        </Table.RowHeader>
      ) : (
        <></>
      )}
      <Table.Cell data-testid={`name-user-${uid}`}>
        <UserLink
          uid={uid}
          htmlUrl={htmlUrl}
          name={name}
          pronouns={pronouns}
          avatarUrl={avatarUrl}
          enrollments={enrollments}
        />
      </Table.Cell>
      {canViewLoginIdColumn ? (
        <Table.Cell data-testid={`login-id-user-${uid}`}>
          <Text>{loginId}</Text>
        </Table.Cell>
      ) : (
        <></>
      )}
      {canViewSisIdColumn ? (
        <Table.Cell data-testid={`sis-id-user-${uid}`}>
          <Text>{sisId}</Text>
        </Table.Cell>
      ) : (
        <></>
      )}
      {!hideSectionsOnCourseUsersPage ? (
        <Table.Cell data-testid={`section-name-user-${uid}`}>{renderSections()}</Table.Cell>
      ) : (
        <></>
      )}
      <Table.Cell data-testid={`role-user-${uid}`}>
        <UserRole enrollments={enrollments} />
      </Table.Cell>
      {canReadReports ? (
        <Table.Cell data-testid={`last-activity-user-${uid}`}>
          <UserLastActivity enrollments={enrollments} />
        </Table.Cell>
      ) : (
        <></>
      )}
      {canReadReports ? (
        <Table.Cell data-testid={`total-activity-user-${uid}`}>
          <View as="div">{totalActivity(enrollments)}</View>
        </Table.Cell>
      ) : (
        <></>
      )}
      {canRemoveUsers || canManage ? (
        <Table.Cell textAlign="end">
          <UserMenu
            uid={uid}
            name={name}
            htmlUrl={htmlUrl}
            enrollments={enrollments}
            customLinks={customLinks}
            canManage={canManage}
            canRemoveUsers={canRemoveUsers}
            onResendInvitation={onResendInvitationHandler}
            onLinkStudents={onLinkStudentsHandler}
            onEditSections={onEditSectionsHandler}
            onEditRoles={onEditRolesHandler}
            onReactivateUser={onReactivateUserHandler}
            onDeactivateUser={onDeactivateUserHandler}
            onRemoveUser={onRemoveUserHandler}
            onCustomLinkSelect={onCustomLinkSelectHandler}
          />
        </Table.Cell>
      ) : (
        <></>
      )}
    </Table.Row>
  )
}

export default RosterTableRow
