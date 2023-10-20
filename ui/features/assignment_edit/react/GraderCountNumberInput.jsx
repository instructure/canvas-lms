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

import {number, string} from 'prop-types'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {NumberInput} from '@instructure/ui-number-input'

const I18n = useI18nScope('GraderCountNumberInput')

const DEFAULT_GRADER_COUNT = 2

function availableGradersText(availableGradersCount) {
  if (availableGradersCount === 1) {
    return I18n.t('There is currently 1 available grader')
  }

  return I18n.t('There are currently %{availableGradersCount} available graders', {
    availableGradersCount,
  })
}

export default class GraderCountNumberInput extends React.Component {
  static propTypes = {
    currentGraderCount: number,
    locale: string.isRequired,
    availableGradersCount: number.isRequired,
  }

  static defaultProps = {
    currentGraderCount: null,
  }

  state = {
    graderCount:
      this.props.currentGraderCount ||
      Math.min(this.props.availableGradersCount, DEFAULT_GRADER_COUNT),
    messages: [],
  }

  generateMessages(newValue, eventType) {
    if (newValue === '' && eventType !== 'blur') {
      return []
    } else if (newValue === '0' || newValue === '') {
      return [{text: I18n.t('Must have at least 1 grader'), type: 'error'}]
    }

    const current = parseInt(newValue, 10)
    if (current > this.props.availableGradersCount) {
      return [{text: availableGradersText(this.props.availableGradersCount), type: 'hint'}]
    }

    return []
  }

  handleNumberInputBlur(value) {
    if (value === '') {
      this.setState({messages: this.generateMessages(value, 'blur')})
    }
  }

  handleNumberInputChange(value) {
    if (value === '') {
      this.setState({graderCount: '', messages: this.generateMessages(value, 'change')})
    } else {
      const match = value.match(/\d+/)
      if (match) {
        this.setState({graderCount: match[0], messages: this.generateMessages(value, 'change')})
      }
    }
  }

  render() {
    const label = (
      <strong className="ModeratedGrading__GraderCountInputLabelText">
        {I18n.t('Number of graders')}
      </strong>
    )
    return (
      <div className="ModeratedGrading__GraderCountInputContainer">
        <NumberInput
          id="grader_count"
          value={this.state.graderCount.toString()}
          renderLabel={label}
          locale={this.props.locale}
          max={this.props.availableGradersCount.toString()}
          messages={this.state.messages}
          min="1"
          onChange={e => {
            if (e.type !== 'blur') this.handleNumberInputChange(e.target.value)
          }}
          onBlur={e => this.handleNumberInputBlur(e.target.value)}
          showArrows={false}
          width="5rem"
        />
      </div>
    )
  }
}
