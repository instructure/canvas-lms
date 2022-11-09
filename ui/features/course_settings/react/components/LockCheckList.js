/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Checkbox} from '@instructure/ui-checkbox'
import propTypes from '@canvas/blueprint-courses/react/propTypes'
import {lockLabels} from '@canvas/blueprint-courses/react/labels'

export default class LockCheckList extends React.Component {
  static propTypes = {
    locks: propTypes.itemLocks.isRequired,
    lockableAttributes: propTypes.lockableAttributeList.isRequired,
    onChange: PropTypes.func,
    formName: PropTypes.string.isRequired,
  }

  static defaultProps = {
    onChange: () => {},
  }

  constructor(props) {
    super(props)
    this.state = {
      locks: props.locks,
    }
    this.onChangeFunctions = this.props.lockableAttributes.reduce((object, item) => {
      object[item] = e => this.onChange(e, item)
      return object
    }, {})
  }

  onChange = (e, value) => {
    const locks = this.state.locks
    locks[value] = e.target.checked
    this.setState(
      {
        locks,
      },
      () => this.props.onChange(locks)
    )
  }

  render() {
    return (
      <div>
        {this.props.lockableAttributes.map(item => (
          <div key={item} className="bcs_check_box-group">
            <input type="hidden" name={`course${this.props.formName}[${item}]`} value={false} />
            <Checkbox
              name={`course${this.props.formName}[${item}]`}
              size="small"
              label={lockLabels[item]}
              value={(this.state.locks[item] || false).toString()}
              checked={this.state.locks[item]}
              onChange={this.onChangeFunctions[item]}
            />
          </div>
        ))}
      </div>
    )
  }
}
