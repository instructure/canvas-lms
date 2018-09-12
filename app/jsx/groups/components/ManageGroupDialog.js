/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!student_groups'
import _ from 'underscore'
import $ from 'jquery'
import React from 'react'
import createReactClass from 'create-react-class'
import BackboneState from '../../groups/mixins/BackboneState'
import PaginatedUserCheckList from '../../groups/components/PaginatedUserCheckList'
import InfiniteScroll from '../../groups/mixins/InfiniteScroll'
import 'jquery.instructure_forms'

const ManageGroupDialog = createReactClass({
  displayName: 'ManageGroupDialog',
  mixins: [BackboneState, InfiniteScroll],

  loadMore() {
    this.props.loadMore()
  },

  getInitialState() {
    return {
      userCollection: this.props.userCollection,
      checked: this.props.checked,
      name: this.props.name
    }
  },

  handleFormSubmit(e) {
    e.preventDefault()
    let errors = false
    if (this.state.name.length == 0) {
      $(this.refs.nameInput).errorBox(I18n.t('Group name is required'))
      errors = true
    }
    if (this.props.maxMembership && this.state.checked.length > this.props.maxMembership) {
      $(this.refs.userList).errorBox(I18n.t('Too many members'))
      errors = true
    }
    if (!errors) {
      this.props.updateGroup(this.props.groupId, this.state.name, this.state.checked)
      this.props.closeDialog(e)
    }
  },

  _onUserCheck(user, isChecked) {
    this.setState({
      checked: isChecked
        ? this.state.checked.concat(user.id)
        : _.without(this.state.checked, user.id)
    })
  },

  render() {
    const users = this.state.userCollection.toJSON().filter(u => u.id !== ENV.current_user_id)
    let inviteLimit = null
    if (this.props.maxMembership) {
      const className = this.state.checked.length > this.props.maxMembership ? 'text-error' : null
      inviteLimit = (
        <span>
          <span className="screenreader-only" aria-live="polite" aria-atomic="true">
            {I18n.t('%{member_count} members out of maximum of %{max_membership}', {
              member_count: this.state.checked.length,
              max_membership: this.props.maxMembership
            })}
          </span>
          <span className={className} aria-hidden="true">
            ({this.state.checked.length}/{this.props.maxMembership})
          </span>
        </span>
      )
    }

    return (
      <div id="manage_group_form">
        <form className="form-dialog" onSubmit={this.handleFormSubmit}>
          <div ref="scrollElement" className="form-dialog-content">
            <table className="formtable">
              <tr>
                <td>
                  <label htmlFor="group_name">{I18n.t('Group Name')}</label>
                </td>
                <td>
                  <input
                    ref="nameInput"
                    id="group_name"
                    type="text"
                    name="name"
                    maxLength="200"
                    value={this.state.name}
                    onChange={event => this.setState({name: event.target.value})}
                  />
                </td>
              </tr>
              <tr>
                <td>
                  <label aria-live="polite" aria-atomic="true">
                    {I18n.t('Members')} {inviteLimit}
                  </label>
                </td>
                <td>
                  <PaginatedUserCheckList
                    ref="userList"
                    checked={this.state.checked}
                    permanentUsers={[ENV.current_user]}
                    users={users}
                    onUserCheck={this._onUserCheck}
                  />
                </td>
              </tr>
            </table>
          </div>
          <div className="form-controls">
            <button className="btn confirm-dialog-cancel-btn" onClick={this.props.closeDialog}>
              {I18n.t('Cancel')}
            </button>
            <button className="btn btn-primary confirm-dialog-confirm-btn" type="submit">
              {I18n.t('Submit')}
            </button>
          </div>
        </form>
      </div>
    )
  }
})

export default ManageGroupDialog
