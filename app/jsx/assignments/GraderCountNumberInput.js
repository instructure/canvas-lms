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
import I18n from 'i18n!assignments'
import NumberInput from '@instructure/ui-core/lib/components/NumberInput'

const DEFAULT_GRADER_COUNT = 2

export default class GraderCountNumberInput extends React.Component {
  static propTypes = {
    currentGraderCount: number,
    locale: string.isRequired,
    maxGraderCount: number.isRequired
  }

  static defaultProps = {
    currentGraderCount: null
  }

  constructor(props) {
    super(props)
    this.generateMessages = this.generateMessages.bind(this)
    this.handleNumberInputBlur = this.handleNumberInputBlur.bind(this)
    this.handleNumberInputChange = this.handleNumberInputChange.bind(this)
    this.state = {
      graderCount: props.currentGraderCount || Math.min(props.maxGraderCount, DEFAULT_GRADER_COUNT),
      messages: []
    }
  }

  generateMessages(newValue, eventType) {
    if (newValue === '' && eventType !== 'blur') {
      return []
    } else if (newValue === '0' || newValue === '') {
      return [{text: I18n.t('Must have at least 1 grader'), type: 'error'}]
    }

    const current = parseInt(newValue, 10)
    if (current > this.props.maxGraderCount) {
      return [
        {
          text: I18n.t('There are currently %{max} available graders', {
            max: this.props.maxGraderCount
          }),
          type: 'hint'
        }
      ]
    }

    return []
  }

  handleNumberInputBlur({target: {value}}) {
    if (value === '') {
      this.setState({messages: this.generateMessages(value, 'blur')})
    }
  }

  handleNumberInputChange({target: {value}}) {
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
          value={this.state.graderCount.toString()}
          label={label}
          locale={this.props.locale}
          max={this.props.maxGraderCount.toString()}
          messages={this.state.messages}
          min="1"
          name="grader_count"
          onChange={this.handleNumberInputChange}
          onBlur={this.handleNumberInputBlur}
          showArrows={false}
          width="5rem"
        />
      </div>
    )
  }
}
