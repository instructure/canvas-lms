/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'
import Assignment from './assignment'
import SelectButton from './select-button'
import assignmentShape from '../shapes/assignment-shape'

const I18n = useI18nScope('choose_mastery_path')

const {func, number, arrayOf} = PropTypes

export default class PathOption extends React.Component {
  static propTypes = {
    assignments: arrayOf(assignmentShape).isRequired,
    optionIndex: number.isRequired,
    setId: number.isRequired,
    selectedOption: number,
    selectOption: func.isRequired,
  }

  selectOption = () => {
    this.props.selectOption(this.props.setId)
  }

  render() {
    const {selectedOption, setId, optionIndex} = this.props
    const disabled =
      selectedOption !== null && selectedOption !== undefined && selectedOption !== setId
    const selected = selectedOption === setId

    const optionClasses = classNames({
      'item-group-container': true,
      'cmp-option': true,
      'cmp-option__selected': selected,
      'cmp-option__disabled': disabled,
    })

    return (
      <div className={optionClasses}>
        <div className="item-group">
          <div className="ig-header">
            <span className="name">{I18n.t('Option %{index}', {index: optionIndex + 1})}</span>
            <SelectButton
              isDisabled={disabled}
              isSelected={selected}
              onSelect={this.selectOption}
            />
          </div>
          <ul className="ig-list">
            {this.props.assignments.map((assg, i) => (
              // eslint-disable-next-line react/no-array-index-key
              <Assignment key={i} assignment={assg} isSelected={selected} />
            ))}
          </ul>
        </div>
      </div>
    )
  }
}
