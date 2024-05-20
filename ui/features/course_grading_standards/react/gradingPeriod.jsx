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

import * as tz from '@canvas/datetime'
import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import GradingPeriodTemplate from './gradingPeriodTemplate'
import DateHelper from '@canvas/datetime/dateHelper'

class GradingPeriod extends React.Component {
  static propTypes = {
    title: PropTypes.string.isRequired,
    weight: PropTypes.number,
    weighted: PropTypes.bool.isRequired,
    startDate: PropTypes.instanceOf(Date).isRequired,
    endDate: PropTypes.instanceOf(Date).isRequired,
    closeDate: PropTypes.instanceOf(Date).isRequired,
    id: PropTypes.string.isRequired,
    updateGradingPeriodCollection: PropTypes.func.isRequired,
    onDeleteGradingPeriod: PropTypes.func.isRequired,
    disabled: PropTypes.bool.isRequired,
    readOnly: PropTypes.bool.isRequired,
    permissions: PropTypes.shape({
      update: PropTypes.bool.isRequired,
      delete: PropTypes.bool.isRequired,
    }).isRequired,
  }

  static defaultProps = {
    weight: null,
  }

  state = {
    title: this.props.title,
    startDate: this.props.startDate,
    endDate: this.props.endDate,
    weight: this.props.weight,
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setState({
      title: nextProps.title,
      startDate: nextProps.startDate,
      endDate: nextProps.endDate,
      weight: nextProps.weight,
    })
  }

  onTitleChange = event => {
    this.setState({title: event.target.value}, function () {
      this.props.updateGradingPeriodCollection(this)
    })
  }

  onDateChange = (dateType, id) => {
    const $date = $(`#${id}`)
    const isValidDate = !($date.data('invalid') || $date.data('blank'))
    let updatedDate = isValidDate ? $date.data('unfudged-date') : new Date('invalid date')

    if (dateType === 'endDate' && DateHelper.isMidnight(updatedDate)) {
      updatedDate = tz.changeToTheSecondBeforeMidnight(updatedDate)
    }

    const updatedState = {}
    updatedState[dateType] = updatedDate
    this.setState(updatedState, function () {
      this.replaceInputWithDate(dateType, $date)
      this.props.updateGradingPeriodCollection(this)
    })
  }

  replaceInputWithDate = (dateType, dateElement) => {
    const date = this.state[dateType]
    dateElement.val(DateHelper.formatDatetimeForDisplay(date))
  }

  render() {
    return (
      <GradingPeriodTemplate
        key={this.props.id}
        ref={c => (this.templateRef = c)}
        id={this.props.id}
        title={this.props.title}
        weight={this.props.weight}
        weighted={this.props.weighted}
        startDate={this.props.startDate}
        endDate={this.props.endDate}
        closeDate={this.props.closeDate || this.props.endDate}
        permissions={this.props.permissions}
        disabled={this.props.disabled}
        readOnly={this.props.readOnly}
        onDeleteGradingPeriod={this.props.onDeleteGradingPeriod}
        onDateChange={this.onDateChange}
        onTitleChange={this.onTitleChange}
      />
    )
  }
}

export default GradingPeriod
