/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {string, func, object, shape, arrayOf} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconMasqueradeLine,
  IconMessageLine,
  IconEditLine,
  IconCalendarClockLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import CreateOrUpdateUserModal from './CreateOrUpdateUserModal'
import UserLink from './UserLink'
import {TempEnrollModal} from '@canvas/temporary-enrollment/react/TempEnrollModal'

const I18n = useI18nScope('account_course_user_search')

export default function UsersListRow({
  accountId,
  user,
  permissions,
  handleSubmitEditUserForm,
  roles,
}) {
  // don't show tempEnroll if permission to create enrollments are missing
  const canTempEnroll =
    permissions.can_temp_enroll &&
    (permissions.can_manage_admin_users ||
      (permissions.can_add_designer &&
        permissions.can_add_student &&
        permissions.can_add_teacher &&
        permissions.can_add_ta &&
        permissions.can_add_observer))

  const enrollPerm = {
    teacher: permissions.can_add_teacher || permissions.can_manage_admin_users,
    ta: permissions.can_add_ta || permissions.can_manage_admin_users,
    student: permissions.can_add_student || permissions.can_manage_admin_users,
    observer: permissions.can_add_observer || permissions.can_manage_admin_users,
    designer: permissions.can_add_observer || permissions.can_manage_admin_users,
  }

  return (
    <Table.Row>
      <Table.RowHeader>
        <UserLink
          href={`/accounts/${accountId}/users/${user.id}`}
          avatarName={user.short_name}
          name={user.sortable_name}
          avatar_url={user.avatar_url}
          size="x-small"
        />
      </Table.RowHeader>
      <Table.Cell data-heap-redact-text="">{user.email}</Table.Cell>
      <Table.Cell data-heap-redact-text="">{user.sis_user_id}</Table.Cell>
      <Table.Cell>{user.last_login && <FriendlyDatetime dateTime={user.last_login} />}</Table.Cell>
      <Table.Cell>
        {canTempEnroll && (
          <TempEnrollModal
            user={user}
            canReadSIS={permissions.can_read_sis}
            permissions={enrollPerm}
            accountId={accountId}
            roles={roles}
          >
            <Tooltip
              data-testid="user-list-row-tooltip"
              renderTip={I18n.t('Temporarily enroll %{name}', {name: user.name})}
            >
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Temporarily enroll %{name}', {name: user.name})}
              >
                <IconCalendarClockLine
                  title={I18n.t('Temporarily enroll %{name}', {name: user.name})}
                />
              </IconButton>
            </Tooltip>
          </TempEnrollModal>
        )}
        {permissions.can_masquerade && (
          <Tooltip
            data-testid="user-list-row-tooltip"
            renderTip={I18n.t('Act as %{name}', {name: user.name})}
          >
            <IconButton
              withBorder={false}
              withBackground={false}
              size="small"
              href={`/users/${user.id}/masquerade`}
              screenReaderLabel={I18n.t('Act as %{name}', {name: user.name})}
            >
              <IconMasqueradeLine title={I18n.t('Act as %{name}', {name: user.name})} />
            </IconButton>
          </Tooltip>
        )}
        {permissions.can_message_users && (
          <Tooltip
            data-testid="user-list-row-tooltip"
            renderTip={I18n.t('Send message to %{name}', {name: user.name})}
          >
            <IconButton
              data-heap-redact-attributes="href"
              withBorder={false}
              withBackground={false}
              size="small"
              href={`/conversations?user_name=${user.name}&user_id=${user.id}`}
              screenReaderLabel={I18n.t('Send message to %{name}', {name: user.name})}
            >
              <IconMessageLine title={I18n.t('Send message to %{name}', {name: user.name})} />
            </IconButton>
          </Tooltip>
        )}
        {permissions.can_edit_users && (
          <CreateOrUpdateUserModal
            createOrUpdate="update"
            url={`/accounts/${accountId}/users/${user.id}`}
            user={user}
            afterSave={handleSubmitEditUserForm}
          >
            <span>
              <Tooltip
                data-testid="user-list-row-tooltip"
                renderTip={I18n.t('Edit %{name}', {name: user.name})}
              >
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  size="small"
                  screenReaderLabel={I18n.t('Edit %{name}', {name: user.name})}
                >
                  <IconEditLine title={I18n.t('Edit %{name}', {name: user.name})} />
                </IconButton>
              </Tooltip>
            </span>
          </CreateOrUpdateUserModal>
        )}
      </Table.Cell>
    </Table.Row>
  )
}

UsersListRow.propTypes = {
  accountId: string.isRequired,
  user: CreateOrUpdateUserModal.propTypes.user.isRequired,
  handleSubmitEditUserForm: func.isRequired,
  permissions: object.isRequired,
  roles: arrayOf(
    shape({
      id: string.isRequired,
      label: string.isRequired,
    })
  ).isRequired,
}

UsersListRow.displayName = 'Row'
