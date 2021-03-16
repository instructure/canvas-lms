/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import {arrayOf, func, number} from 'prop-types'
import {Select} from '@instructure/ui-forms'

import {OverrideShape} from '../../assignmentData'

import {Flex} from '@instructure/ui-flex'

export default class Filters extends React.Component {
  static propTypes = {
    onChange: func,
    overrides: arrayOf(OverrideShape).isRequired,
    numAttempts: number.isRequired
  }

  static defaultProps = {
    onChange: () => {}
  }

  overrideName(assignedTo) {
    return (
      assignedTo.sectionName ||
      assignedTo.studentName ||
      (assignedTo.hasOwnProperty('groupName') && (assignedTo.groupName || 'unnamed group')) ||
      ''
    )
  }

  onChangeAssignTo = (e, option) => {
    const value = option.value === 'all' ? null : option.value
    this.props.onChange('assignTo', value)
  }

  onChangeAttempt = (e, option) => {
    const value = option.value === 'all' ? null : Number.parseInt(option.value, 10)
    this.props.onChange('attempt', value)
  }

  onChangeStatus = (e, option) => {
    const value = option.value === 'all' ? null : option.value
    this.props.onChange('status', value)
  }

  renderAssignToFilterOptions() {
    const everyone = [
      <option key="all" value="all">
        {I18n.t('Everyone')}
      </option>
    ]
    const others = this.props.overrides.map(override => {
      const pieces =
        override.set.__typename === 'AdhocStudents' ? override.set.students : [override.set]
      const display = pieces.map(this.overrideName).join(', ')
      return (
        <option key={override.lid} value={override.lid}>
          {display}
        </option>
      )
    })
    return everyone.concat(others)
  }

  renderAttemptFilterOptions() {
    const options = [
      <option key="all" value="all">
        {I18n.t('All')}
      </option>
    ]
    for (let i = 1; i <= this.props.numAttempts; i++) {
      options.push(
        <option key={i} value={i.toString()}>
          {I18n.t('Attempt %{count}', {count: i})}
        </option>
      )
    }
    return options
  }

  renderStatusFilterOptions() {
    return [
      <option key="all" value="all">
        {I18n.t('All')}
      </option>,
      <option key="excused" value="excused">
        {I18n.t('Excused')}
      </option>,
      <option key="late" value="late">
        {I18n.t('Late')}
      </option>,
      <option key="missing" value="missing">
        {I18n.t('Missing')}
      </option>
    ]
  }

  render() {
    return (
      <Flex as="div" margin="medium 0 0 0" wrapItems>
        <Flex.Item>
          <Select
            label={I18n.t('Assign To')}
            onChange={this.onChangeAssignTo}
            data-testid="assignToFilter"
          >
            {this.renderAssignToFilterOptions()}
          </Select>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Select
            label={I18n.t('attempts.filter', 'Attempts')}
            onChange={this.onChangeAttempt}
            data-testid="attemptFilter"
          >
            {this.renderAttemptFilterOptions()}
          </Select>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Select
            label={I18n.t('Status')}
            onChange={this.onChangeStatus}
            data-testid="statusFilter"
          >
            {this.renderStatusFilterOptions()}
          </Select>
        </Flex.Item>
      </Flex>
    )
  }
}
