/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {List} from 'immutable'
import shortid from '@canvas/shortid'
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conditional_release')

const {object, func} = PropTypes

class AssignmentList extends React.Component {
  static get propTypes() {
    return {
      assignments: object.isRequired,
      disabledAssignments: object,
      selectedAssignments: object,
      onSelectAssignment: func.isRequired,
      onUnselectAssignment: func.isRequired,
    }
  }

  static get defaultProps() {
    return {
      disabledAssignments: List(),
      selectedAssignments: List(),
    }
  }

  constructor() {
    super()

    this.toggleItemSelection = this.toggleItemSelection.bind(this)
  }

  toggleItemSelection(e) {
    const id = e.target.value
    const checked = e.target.checked

    if (checked) {
      this.props.onSelectAssignment(id)
    } else {
      this.props.onUnselectAssignment(id)
    }
  }

  itemClass(category) {
    if (category === 'page') {
      return 'document'
    }
    return category
  }

  renderItem(item, i) {
    const isDisabled = this.props.disabledAssignments.includes(item.get('id').toString())
    const isSelected = !isDisabled && this.props.selectedAssignments.includes(item.get('id'))
    const itemId = shortid()

    const itemClasses = {
      'cr-assignments-list__item': true,
      'cr-assignments-list__item__disabled': isDisabled,
      'cr-assignments-list__item__selected': isSelected,
    }

    return (
      <li
        key={i}
        aria-label={I18n.t('%{item_category} category icon for item name %{item_name}', {
          item_category: item.get('category'),
          item_name: item.get('name'),
        })}
        className={classNames(itemClasses)}
      >
        <input
          disabled={isDisabled}
          id={itemId}
          type="checkbox"
          value={item.get('id')}
          onChange={this.toggleItemSelection}
          defaultChecked={isSelected}
        />
        <label htmlFor={itemId} className="cr-label__cbox">
          <span className="cr-assignments-list__item__icon">
            <i aria-hidden={true} className={`icon-${this.itemClass(item.get('category'))}`} />
          </span>
          <span className="ic-Label__text">{item.get('name')}</span>
        </label>
      </li>
    )
  }

  render() {
    if (this.props.assignments.size) {
      return (
        <ul className="cr-assignments-list">
          {this.props.assignments.map((item, i) => {
            return this.renderItem(item, i)
          })}
        </ul>
      )
    } else {
      return <p>{I18n.t('No items found')}</p>
    }
  }
}

export default AssignmentList
