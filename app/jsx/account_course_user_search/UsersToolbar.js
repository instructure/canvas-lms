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
import {string, func, shape, object, arrayOf} from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import preventDefault from 'compiled/fn/preventDefault'
import NewUserModal from './NewUserModal'
import IcInput from './IcInput'
import IcSelect from './IcSelect'

export default class UsersToolbar extends React.Component {
  static propTypes = {
    onUpdateFilters: func.isRequired,
    onApplyFilters: func.isRequired,
    search_term: string,
    role_filter_id: string,
    errors: shape({search_term: string}),
    accountId: string,

    handlers: shape({
      handleAddNewUser: func,
      handleAddNewUserFormErrors: func
    }),
    userList: object.isRequired,
    roles: arrayOf(
      shape({
        id: string.isRequired,
        label: string.isRequired
      })
    ).isRequired
  }

  static defaultProps = {
    search_term: '',
    role_filter_id: '',
    errors: {},
    accountId: '',
    handlers: {},
    roles: []
  }

  render() {
    return (
      <div>
        <form
          className="user_search_bar"
          onSubmit={preventDefault(this.props.onApplyFilters)}
        >
          <div className="grid-row">
            <div className="col-xs-12 col-md-9">
              <div className="users-list-toolbar-form">
                <IcSelect
                  value={this.props.role_filter_id}
                  onChange={e => this.props.onUpdateFilters({role_filter_id: e.target.value})}
                >
                  <option key="all" value="">
                    {I18n.t('All Roles')}
                  </option>
                  {this.props.roles.map(role => (
                    <option key={role.id} value={role.id}>
                      {role.label}
                    </option>
                  ))}
                </IcSelect>
                <IcInput
                  value={this.props.search_term}
                  placeholder={I18n.t('Search people...')}
                  onChange={e => this.props.onUpdateFilters({search_term: e.target.value})}
                  error={this.props.errors.search_term}
                  type="search"
                />
              </div>
            </div>
            <div className="col-xs-12 col-md-3">
              <div className="users-list-toolbar-actions">
                <div className="users-list-toolbar-actions__layout">
                  {window.ENV.PERMISSIONS.can_create_users && (
                    <button
                      className="Button add_user"
                      type="button"
                      onClick={() => this.addUserModal.openModal()}
                    >
                      <i className="icon-plus" /> {I18n.t('People')}
                    </button>
                  )}
                  &nbsp;
                  <div className="al-dropdown__container">
                    <button id="peopleOptionsBtn" className="al-trigger Button" type="button">
                      <i className="icon-more" />
                      <span className="screenreader-only">{I18n.t('People Options')}</span>
                    </button>
                    <ul className="al-options" role="menu" aria-hidden="true">
                      <li>
                        <a
                          href={`/accounts/${this.props.accountId}/avatars`}
                          className="icon-student-view"
                          id="manageStudentsLink"
                          role="menuitem"
                        >
                          {I18n.t('Manage profile pictures')}
                        </a>
                      </li>
                      <li>
                        <a
                          href={`/accounts/${this.props.accountId}/groups`}
                          className="icon-group"
                          id="viewUserGroupLink"
                          role="menuitem"
                        >
                          {I18n.t('View user groups')}
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
        <NewUserModal
          ref={c => (this.addUserModal = c)}
          userList={this.props.userList}
          handlers={this.props.handlers}
        />
      </div>
    )
  }
}
