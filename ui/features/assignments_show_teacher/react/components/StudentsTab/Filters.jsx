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
import {useScope as useI18nScope} from '@canvas/i18n'
import {arrayOf, func, number} from 'prop-types'
import {Select} from '@instructure/ui-select'

import {OverrideShape} from '../../assignmentData'

import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('assignments_2')

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */
export default class Filters extends React.Component {
  static propTypes = {
    onChange: func,
    overrides: arrayOf(OverrideShape).isRequired,
    numAttempts: number.isRequired,
  }

  static defaultProps = {
    onChange: () => {},
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
      <Select.Option id="all" key="all" value="all">
        {I18n.t('Everyone')}
      </Select.Option>,
    ]
    const others = this.props.overrides.map(override => {
      const pieces =
        override.set.__typename === 'AdhocStudents' ? override.set.students : [override.set]
      const display = pieces.map(this.overrideName).join(', ')
      return (
        <Select.Option id={override.lid} key={override.lid} value={override.lid}>
          {display}
        </Select.Option>
      )
    })
    return everyone.concat(others)
  }

  renderAttemptFilterOptions() {
    const options = [
      <Select.Option id="all" key="all" value="all">
        {I18n.t('All')}
      </Select.Option>,
    ]
    for (let i = 1; i <= this.props.numAttempts; i++) {
      options.push(
        <Select.Option id={i} key={i} value={i.toString()}>
          {I18n.t('Attempt %{count}', {count: i})}
        </Select.Option>
      )
    }
    return options
  }

  renderStatusFilterOptions() {
    return [
      <Select.Option id="all" key="all" value="all">
        {I18n.t('All')}
      </Select.Option>,
      <Select.Option id="excused" key="excused" value="excused">
        {I18n.t('Excused')}
      </Select.Option>,
      <Select.Option id="late" key="late" value="late">
        {I18n.t('Late')}
      </Select.Option>,
      <Select.Option id="missing" key="missing" value="missing">
        {I18n.t('Missing')}
      </Select.Option>,
    ]
  }

  render() {
    return (
      <Flex as="div" margin="medium 0 0 0" wrap="wrap">
        <Flex.Item>
          <Select
            renderLabel={I18n.t('Assign To')}
            onChange={this.onChangeAssignTo}
            data-testid="assignToFilter"
          >
            {this.renderAssignToFilterOptions()}
          </Select>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Select
            renderLabel={I18n.t('attempts.filter', 'Attempts')}
            onChange={this.onChangeAttempt}
            data-testid="attemptFilter"
          >
            {this.renderAttemptFilterOptions()}
          </Select>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Select
            renderLabel={I18n.t('Status')}
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
