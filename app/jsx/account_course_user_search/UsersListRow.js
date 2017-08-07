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
import PropTypes from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import $ from 'jquery'
import EditUserDetailsDialog from 'jsx/shared/EditUserDetailsDialog'
import 'jquery.instructure_date_and_time'

const { object, string, func, shape, bool } = PropTypes

  export default class UsersListRow extends React.Component {
    static propTypes = {
      accountId: string,
      timezones: object.isRequired,
      user: shape({
        id: string.isRequired,
        name: string.isRequired,
        avatar_url: string,
      }).isRequired,
      handlers: shape({
        handleOpenEditUserDialog: func,
        handleSubmitEditUserForm: func,
        handleCloseEditUserDialog: func
      }).isRequired,
      permissions: shape({
        can_masquerade: bool,
        can_message_users: bool,
        can_edit_users: bool
      }).isRequired
    }

    renderLinks () {
      const links = [];
      const { id, name } = this.props.user;
      const { handleOpenEditUserDialog } = this.props.handlers;
      if (this.props.permissions.can_masquerade) {
        links.push(
          <a
            className="Button Button--icon-action user_actions_js_test"
            key="masqueradeLink"
            href={`/users/${id}/masquerade`}
          >
            <span className="screenreader-only">{I18n.t("Masquerade as %{name}", {name})}</span>
            <i className="icon-masquerade" aria-hidden="true"></i>
          </a>
        );
      }

      if (this.props.permissions.can_message_users) {
        links.push(
          <a
            className="Button Button--icon-action user_actions_js_test"
            key="messageUserLink"
            href={`/conversations?user_name=${name}&user_id=${id}`}
          >
            <span className="screenreader-only">{I18n.t("Send message to %{name}", {name})}</span>
            <i className="icon-message" aria-hidden="true"></i>
          </a>
        );
      }

      if (this.props.permissions.can_edit_users) {
        links.push(
          <button
            className="Button Button--icon-action user_actions_js_test"
            key="canEditUserLink"
            onClick={handleOpenEditUserDialog.bind(null, this.props.user)}
            type="button"
          >
            <span className="screenreader-only">{I18n.t("Edit %{name}", {name})}</span>
            <i className="icon-edit" aria-hidden="true"></i>
          </button>
        );
      }

      return (
        <div className="courses-user-list-actions">
          {links}
        </div>
      );
    }

    render () {
      const { id, name, sis_user_id, email, avatar_url, last_login, editUserDialogOpen } = this.props.user;
      const { handleSubmitEditUserForm, handleCloseEditUserDialog } = this.props.handlers;
      const url = `/accounts/${this.props.accountId}/users/${id}`;

      return (
        <div role='row' className="grid-row middle-xs pad-box-mini border border-b">
          <div className="col-xs-3" role="gridcell">
            <div className="grid-row middle-xs">
              <span className="userAvatar">
                <span className="userUrl">
                  {!!avatar_url &&
                    <span className="ic-avatar UserListRow__Avatar">
                      <img src={avatar_url} alt={`User avatar for ${name}`} />
                    </span>
                  }
                  <a href={url}>{name}</a>
                </span>
              </span>
            </div>
          </div>
          <div className="col-xs-3" role='gridcell'>
            {email}
          </div>

          <div className="col-xs-1" role='gridcell'>
            {sis_user_id}
          </div>

          <div className="col-xs-2" role='gridcell'>
            {$.datetimeString(last_login)}
          </div>

          <div className="col-xs-2" role='gridcell'>
            {this.renderLinks()}
            <EditUserDetailsDialog
              submitEditUserForm={handleSubmitEditUserForm}
              user={this.props.user}
              timezones={this.props.timezones}
              isOpen={editUserDialogOpen}
              contentLabel={I18n.t('Edit User')}
              onRequestClose={handleCloseEditUserDialog.bind(null, this.props.user)}
            />
          </div>
        </div>
      );
    }
  }
