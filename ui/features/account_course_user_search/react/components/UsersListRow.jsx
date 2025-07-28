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
import {arrayOf, bool, func, object, shape, string} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconEditLine,
  IconMasqueradeLine,
  IconMessageLine,
  IconExportLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import CreateOrUpdateUserModal from './CreateOrUpdateUserModal'
import {CreateDSRModal} from '@canvas/dsr'
import UserLink from './UserLink'
import TempEnrollUsersListRow from '@canvas/temporary-enrollment/react/TempEnrollUsersListRow'

const I18n = createI18nScope('account_course_user_search')

export default function UsersListRow({
  accountId,
  user,
  permissions,
  handleSubmitEditUserForm,
  roles,
  includeDeletedUsers,
}) {
  let userLink = `/accounts/${accountId}/users/${user.id}`
  if (includeDeletedUsers && !user.login_id)
    userLink += `?include_deleted_users=${includeDeletedUsers}`
  return (
    <Table.Row>
      <Table.RowHeader>
        <UserLink
          href={userLink}
          avatarName={user.short_name}
          name={user.sortable_name}
          avatar_url={user.avatar_url}
          pronouns={user.pronouns}
          size="x-small"
        />
      </Table.RowHeader>
      <Table.Cell>{user.email}</Table.Cell>
      <Table.Cell>{user.sis_user_id}</Table.Cell>
      <Table.Cell>{user.last_login && <FriendlyDatetime dateTime={user.last_login} />}</Table.Cell>
      <Table.Cell textAlign="end">
        {permissions.can_view_temporary_enrollments &&
          TempEnrollUsersListRow({
            user,
            permissions,
            handleSubmitEditUserForm,
            roles,
          })}
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
        {permissions.can_create_dsr && (
          <CreateDSRModal accountId={accountId} user={user} afterSave={handleSubmitEditUserForm}>
            <span>
              <Tooltip
                data-testid="user-list-row-tooltip"
                renderTip={I18n.t('Create DSR Request for %{name}', {name: user.name})}
              >
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  size="small"
                  screenReaderLabel={I18n.t('Create DSR Request for %{name}', {name: user.name})}
                >
                  <IconExportLine
                    title={I18n.t('Create DSR Request for %{name}', {name: user.name})}
                  />
                </IconButton>
              </Tooltip>
            </span>
          </CreateDSRModal>
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
    }),
  ).isRequired,
  includeDeletedUsers: bool,
}

UsersListRow.displayName = 'Row'
