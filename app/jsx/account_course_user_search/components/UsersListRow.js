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
import {string, func, shape, bool} from 'prop-types'
import Button from '@instructure/ui-core/lib/components/Button'
import Tooltip from '@instructure/ui-core/lib/components/Tooltip'
import IconMasqueradeLine from 'instructure-icons/lib/Line/IconMasqueradeLine'
import IconMessageLine from 'instructure-icons/lib/Line/IconMessageLine'
import IconEditLine from 'instructure-icons/lib/Line/IconEditLine'
import I18n from 'i18n!account_course_user_search'
import FriendlyDatetime from '../../shared/FriendlyDatetime'
import CreateOrUpdateUserModal from '../../shared/components/CreateOrUpdateUserModal'
import UserLink from './UserLink'

export default function UsersListRow({accountId, user, permissions, handleSubmitEditUserForm}) {
  return (
    <tr>
      <th scope="row">
        <UserLink
          href={`/accounts/${accountId}/users/${user.id}`}
          name={user.name}
          avatar_url={user.avatar_url}
          size="x-small"
        />
      </th>
      <td>{user.email}</td>
      <td>{user.sis_user_id}</td>
      <td><FriendlyDatetime dateTime={user.last_login} /></td>
      <td style={{whiteSpace: 'nowrap'}}>
        {permissions.can_masquerade && (
          <Tooltip tip={I18n.t('Act as %{name}', {name: user.name})}>
            <Button variant="icon" size="small" href={`/users/${user.id}/masquerade`}>
              <IconMasqueradeLine height="1.5em" title={I18n.t('Act as %{name}', {name: user.name})} />
            </Button>
          </Tooltip>
        )}
        {permissions.can_message_users && (
          <Tooltip tip={I18n.t('Send message to %{name}', {name: user.name})}>
            <Button
              variant="icon"
              size="small"
              href={`/conversations?user_name=${user.name}&user_id=${user.id}`}
            >
              <IconMessageLine height="1.5em" title={I18n.t('Send message to %{name}', {name: user.name})} />
            </Button>
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
              <Tooltip tip={I18n.t('Edit %{name}', {name: user.name})}>
                <Button variant="icon" size="small">
                  <IconEditLine title={I18n.t('Edit %{name}', {name: user.name})} />
                </Button>
              </Tooltip>
            </span>
          </CreateOrUpdateUserModal>
        )}
      </td>
    </tr>
  )
}

UsersListRow.propTypes = {
  accountId: string.isRequired,
  user: CreateOrUpdateUserModal.propTypes.user.isRequired,
  handleSubmitEditUserForm: func.isRequired,
  permissions: shape({
    can_masquerade: bool,
    can_message_users: bool,
    can_edit_users: bool
  }).isRequired
}
