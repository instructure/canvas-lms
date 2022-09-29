/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, func} from 'prop-types'
import OverrideAssignTo from './OverrideAssignTo'
import OverrideAttempts from './OverrideAttempts'
import OverrideSubmissionTypes from './OverrideSubmissionTypes'
import OverrideDates from './OverrideDates'
import {OverrideShape} from '../../assignmentData'
import {View} from '@instructure/ui-view'

export default class OverrideDetail extends React.Component {
  static propTypes = {
    override: OverrideShape.isRequired,
    onChangeOverride: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  handleChangeDate = (which, value) => {
    this.props.onChangeOverride(which, value)
  }

  renderAssignedTo() {
    return <OverrideAssignTo override={this.props.override} variant="detail" />
  }

  renderDates() {
    return (
      <OverrideDates
        dueAt={this.props.override.dueAt}
        unlockAt={this.props.override.unlockAt}
        lockAt={this.props.override.lockAt}
        onChange={this.handleChangeDate}
        onValidate={this.props.onValidate}
        invalidMessage={this.props.invalidMessage}
        readOnly={this.props.readOnly}
      />
    )
  }

  renderSubmissionTypes() {
    return (
      <View as="div" margin="small 0">
        <OverrideSubmissionTypes
          override={this.props.override}
          onChangeOverride={this.props.onChangeOverride}
          variant="detail"
          readOnly={this.props.readOnly}
        />
      </View>
    )
  }

  renderAttempts() {
    return (
      <OverrideAttempts
        variant="detail"
        allowedAttempts={this.props.override.allowedAttempts}
        onChange={this.props.onChangeOverride}
        readOnly={this.props.readOnly}
      />
    )
  }

  render() {
    return (
      <View as="div" padding="medium" data-testid="OverrideDetail">
        {this.renderAssignedTo()}
        {this.renderDates()}
        {this.renderSubmissionTypes()}
        {this.renderAttempts()}
      </View>
    )
  }
}
