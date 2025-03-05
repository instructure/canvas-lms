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
import {CheckboxGroup, Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'

class PaginatedUserCheckList extends React.Component {
  static defaultProps = {
    permanentUsers: [],
    checked: [],
    labelId: null,
    messages: [],
    label: '',
  }

  _isChecked = id => this.props.checked.includes(id)
  _isPermanentUser = id => this.props.permanentUsers.some(u => u.id === id)

  render() {
    return (
        <CheckboxGroup
          name="paginatedUserChecklist"
          defaultValue={this.props.checked}
          description={this.props.label}
          onChange={(event) => {
            this.props.onUserCheck(event)
          }}
          messages={this.props.messages}
        >
          { [...this.props.permanentUsers, ...this.props.users].map(u => (
            <Checkbox
              data-testid={`user-checkbox-${u.id}`}
              key={`checkbox-${u.id}`}
              label={<Text>{u.name || u.display_name}</Text>}
              value={u.id}
              name="users"
              className="checkbox"
              readOnly={this._isPermanentUser(u.id)}
              disabled={this._isPermanentUser(u.id)}
            />
          ))}
        </CheckboxGroup>
    )
  }
}

export default PaginatedUserCheckList
