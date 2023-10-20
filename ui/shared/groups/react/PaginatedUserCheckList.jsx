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

import React from 'react'

class PaginatedUserCheckList extends React.Component {
  static defaultProps = {
    permanentUsers: [],
    checked: [],
    labelId: null,
  }

  _isChecked = id => this.props.checked.includes(id)

  render() {
    const permanentListItems = this.props.permanentUsers.map(u => (
      <li key={u.id}>
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="checkbox">
          <input checked="true" type="checkbox" disabled="true" readOnly="true" />
          {u.name || u.display_name}
        </label>
      </li>
    ))

    const listItems = this.props.users.map(u => (
      <li key={u.id}>
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="checkbox">
          <input
            checked={this._isChecked(u.id)}
            onChange={e => this.props.onUserCheck(u, e.target.checked)}
            type="checkbox"
          />
          {u.name || u.display_name}
        </label>
      </li>
    ))

    return (
      <ul className="unstyled_list" aria-labelledby={this.props.labelId}>
        {permanentListItems}
        {listItems}
      </ul>
    )
  }
}

export default PaginatedUserCheckList
