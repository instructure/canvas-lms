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
import Button from 'instructure-ui/lib/components/Button'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import IconMasqueradeLine from 'instructure-icons/lib/Line/IconMasqueradeLine'
import IconMessageLine from 'instructure-icons/lib/Line/IconMessageLine'
import IconEditLine from 'instructure-icons/lib/Line/IconEditLine'
import I18n from 'i18n!account_course_user_search'
import {datetimeString} from 'jquery.instructure_date_and_time'
import EditUserDetailsDialog from 'jsx/shared/EditUserDetailsDialog'

export default function UsersListRow({accountId, user, permissions, handlers, timezones}) {
  return (
    <div role="row" className="grid-row middle-xs pad-box-mini border border-b">
      <div className="col-xs-3" role="gridcell">
        <div className="grid-row middle-xs">
          <span className="userAvatar">
            <a className="userUrl" href={`/accounts/${accountId}/users/${user.id}`}>
              {user.avatar_url && (
                <span className="ic-avatar UserListRow__Avatar">
                  <img src={user.avatar_url} alt={`User avatar for ${user.name}`} />
                </span>
              )}
              {user.name}
            </a>
          </span>
        </div>
      </div>
      <div className="col-xs-3" role="gridcell">
        {user.email}
      </div>

      <div className="col-xs-1" role="gridcell">
        {user.sis_user_id}
      </div>

      <div className="col-xs-2" role="gridcell">
        {datetimeString(user.last_login)}
      </div>

      <div className="col-xs-2" role="gridcell">
        <div className="courses-user-list-actions">
          {permissions.can_masquerade && (
            <Tooltip tip={I18n.t('Act as %{name}', {name: user.name})}>
              <Button variant="icon" size="small" href={`/users/${user.id}/masquerade`}>
                <IconMasqueradeLine />
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
                <IconMessageLine />
              </Button>
            </Tooltip>
          )}
          {permissions.can_edit_users && (
            <Tooltip tip={I18n.t('Edit %{name}', {name: user.name})}>
              <Button
                variant="icon"
                size="small"
                onClick={() => handlers.handleOpenEditUserDialog(user)}
              >
                <IconEditLine />
                <EditUserDetailsDialog
                  submitEditUserForm={handlers.handleSubmitEditUserForm}
                  user={user}
                  timezones={timezones}
                  isOpen={user.editUserDialogOpen}
                  contentLabel={I18n.t('Edit User')}
                  onRequestClose={() => handlers.handleCloseEditUserDialog(user)}
                />
              </Button>
            </Tooltip>
          )}
        </div>
      </div>
    </div>
  )
}

UsersListRow.propTypes = {
  accountId: string.isRequired,
  timezones: EditUserDetailsDialog.propTypes.timezones,
  user: EditUserDetailsDialog.propTypes.user,
  handlers: shape({
    handleOpenEditUserDialog: func.isRequired,
    handleSubmitEditUserForm: func.isRequired,
    handleCloseEditUserDialog: func.isRequired
  }).isRequired,
  permissions: shape({
    can_masquerade: bool,
    can_message_users: bool,
    can_edit_users: bool
  }).isRequired
}
