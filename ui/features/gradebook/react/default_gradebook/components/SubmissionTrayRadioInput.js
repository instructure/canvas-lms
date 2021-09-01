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
import {func, number, shape, string, bool} from 'prop-types'
import {RadioInput} from '@instructure/ui-radio-input'

import classnames from 'classnames'
import TimeLateInput from '@canvas/grading/TimeLateInput'

function styles({color, showNumberInput}) {
  return {
    backgroundColor: color,
    height: showNumberInput ? '5rem' : '2rem'
  }
}

export default class SubmissionTrayRadioInput extends React.Component {
  static propTypes = {
    checked: bool.isRequired,
    color: string,
    disabled: bool.isRequired,
    latePolicy: shape({
      lateSubmissionInterval: string.isRequired
    }).isRequired,
    locale: string.isRequired,
    onChange: func.isRequired,
    submission: shape({
      secondsLate: number.isRequired
    }).isRequired,
    text: string.isRequired,
    updateSubmission: func.isRequired,
    value: string.isRequired
  }

  static defaultProps = {
    color: 'transparent'
  }

  constructor(props) {
    super(props)

    this.radioInputClasses = classnames('SubmissionTray__RadioInput', {
      'SubmissionTray__RadioInput-WithBackground': props.color !== 'transparent'
    })
  }

  handleRadioInputChange = event => {
    this.props.onChange(event)
  }

  render() {
    const {
      props: {color}
    } = this

    const showNumberInput = this.props.checked && this.props.value === 'late'

    return (
      <div className={this.radioInputClasses} style={styles({color, showNumberInput})}>
        <RadioInput
          checked={this.props.checked}
          disabled={this.props.disabled}
          name="SubmissionTrayRadioInput"
          label={this.props.text}
          onChange={this.handleRadioInputChange}
          value={this.props.value}
        />

        <TimeLateInput
          key={(this.props.submission.id || 'none').toString()}
          disabled={this.props.disabled}
          lateSubmissionInterval={this.props.latePolicy.lateSubmissionInterval}
          locale={this.props.locale}
          secondsLate={this.props.submission.secondsLate}
          renderLabelBefore={false}
          onSecondsLateUpdated={this.props.updateSubmission}
          width="5rem"
          visible={showNumberInput}
        />
      </div>
    )
  }
}
