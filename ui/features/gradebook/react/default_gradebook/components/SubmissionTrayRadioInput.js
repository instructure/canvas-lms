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
import I18n from 'i18n!gradebook'
import {View} from '@instructure/ui-view'
import {NumberInput} from '@instructure/ui-number-input'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {RadioInput} from '@instructure/ui-radio-input'

import classnames from 'classnames'
import round from 'round'
import NumberHelper from '@canvas/i18n/numberHelper'

function defaultDurationLate(interval, secondsLate) {
  let durationLate = secondsLate / 3600

  if (interval === 'day') {
    durationLate /= 24
  }

  return round(durationLate, 2)
}

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

    const interval = props.latePolicy.lateSubmissionInterval
    this.numberInputLabel = interval === 'day' ? I18n.t('Days late') : I18n.t('Hours late')
    this.numberInputText = interval === 'day' ? I18n.t('Day(s)') : I18n.t('Hour(s)')
    this.radioInputClasses = classnames('SubmissionTray__RadioInput', {
      'SubmissionTray__RadioInput-WithBackground': props.color !== 'transparent'
    })

    this.state = {
      numberInputValue: defaultDurationLate(interval, props.submission.secondsLate)
    }
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    const idOf = submission => submission && submission.id
    const submissionHasChanged = idOf(this.props.submission) !== idOf(nextProps.submission)

    if (nextProps.submission && submissionHasChanged) {
      const interval = nextProps.latePolicy.lateSubmissionInterval
      this.setState({
        numberInputValue: defaultDurationLate(interval, nextProps.submission.secondsLate)
      })
    }
  }

  handleNumberInputBlur = ({target: {value}}) => {
    if (!NumberHelper.validate(value)) {
      return
    }

    const parsedValue = NumberHelper.parse(value)
    const roundedValue = round(parsedValue, 2)
    if (roundedValue === this.state.numberInputValue) {
      return
    }

    let secondsLateOverride = parsedValue * 3600
    if (this.props.latePolicy.lateSubmissionInterval === 'day') {
      secondsLateOverride *= 24
    }

    this.props.updateSubmission({
      latePolicyStatus: 'late',
      secondsLateOverride: Math.trunc(secondsLateOverride)
    })
  }

  handleNumberInputChange = (_event, numberInputValue) => {
    this.setState({numberInputValue})
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

        {showNumberInput && (
          <span className="NumberInput__Container NumberInput__Container-LeftIndent">
            <NumberInput
              value={this.state.numberInputValue.toString()}
              disabled={this.props.disabled}
              inline
              label={<ScreenReaderContent>{this.numberInputLabel}</ScreenReaderContent>}
              locale={this.props.locale}
              min="0"
              onBlur={this.handleNumberInputBlur}
              onChange={this.handleNumberInputChange}
              showArrows={false}
              width="5rem"
            />

            <PresentationContent>
              <View as="div" margin="0 small">
                <Text>{this.numberInputText}</Text>
              </View>
            </PresentationContent>
          </span>
        )}
      </div>
    )
  }
}
