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
import _ from 'underscore'
import UsersListRow from './UsersListRow'

  var { string, array, object } = PropTypes;

  var UsersList = React.createClass({
    propTypes: {
      accountId: string.isRequired,
      users: array.isRequired,
      timezones: object.isRequired,
      permissions: object.isRequired,
      handlers: object.isRequired
    },

    render() {
      const { users, timezones, accountId } = this.props;

      return (
        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Name")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Email")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t("SIS ID")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Last Login")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-2">
              <span className='screenreader-only'>{I18n.t("User option links")}</span>
            </div>
          </div>
          <div className='users-list' role='rowgroup'>
            {
              users.map((user) => {
                return (
                  <UsersListRow
                    handlers={this.props.handlers}
                    key={user.id}
                    timezones={timezones}
                    accountId={accountId}
                    user={user}
                    permissions={this.props.permissions}
                  />
                );
              })
            }
          </div>
        </div>
      );
    }
  });

export default UsersList
