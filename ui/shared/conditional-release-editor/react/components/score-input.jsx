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
import classNames from 'classnames'
import PropTypes from 'prop-types'
import shortid from '@canvas/shortid'

import {useScope as createI18nScope} from '@canvas/i18n'
import GradingTypes from '../grading-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {TextInput} from '@instructure/ui-text-input'

import {
  scoreToPercent,
  percentToScore,
  transformScore,
  getGradingType,
  isNumeric,
} from '../score-helpers'

const I18n = createI18nScope('conditional_release')

const {string, func, object, number} = PropTypes

export default class ScoreInput extends React.Component {
  static get propTypes() {
    return {
      score: number.isRequired,
      triggerAssignment: object.isRequired,
      label: string,
      error: string,
      onScoreChanged: func.isRequired,
    }
  }

  constructor() {
    super()
    this.state = {
      focused: false,
      editingValue: null,
    }

    this.shortid = shortid()

    this.focused = this.focused.bind(this)
    this.blurred = this.blurred.bind(this)
    this.changed = this.changed.bind(this)
  }

  focused(e) {
    // Makes sure cursor appears at the end
    this.setState({focused: true})
    this.moveCursorToEnd(e.target)
  }

  blurred(_e) {
    this.setState({focused: false})
    this.setState({editingValue: null})
  }

  changed(e) {
    this.setState({editingValue: e.target.value})
    this.props.onScoreChanged(scoreToPercent(e.target.value, this.props.triggerAssignment))
  }

  moveCursorToEnd(element) {
    const strLength = element.value.length
    element.selectionStart = element.selectionEnd = strLength
  }

  value() {
    if (!this.state.focused) {
      if (this.props.score === '') {
        return ''
      }
      return transformScore(this.props.score, this.props.triggerAssignment, false)
    } else if (this.state.editingValue) {
      return this.state.editingValue
    } else {
      const currentScore = percentToScore(this.props.score, this.props.triggerAssignment)
      return isNumeric(currentScore) ? I18n.n(currentScore) : currentScore
    }
  }

  hasError() {
    return !!this.props.error
  }

  errorMessage() {
    return (
      <span data-testid="cr-score-input-error" style={{whiteSpace: 'nowrap'}}>
        {this.props.error}
      </span>
    )
  }

  errorMessageId() {
    return 'error-' + this.shortid
  }

  render() {
    const topClasses = {
      'cr-percent-input': true,
      'cr-percent-input--error': this.hasError(),
      'ic-Form-control': true,
      'ic-Form-control--has-error': this.hasError(),
    }

    const optionalProps = {}
    if (this.hasError()) {
      optionalProps['aria-invalid'] = true
      optionalProps['aria-describedby'] = this.errorMessageId()
    }

    let srLabel = this.props.label
    const gradingType = getGradingType(this.props.triggerAssignment)
    if (gradingType && GradingTypes[gradingType]) {
      srLabel = I18n.t('%{label}, as %{gradingType}', {
        label: this.props.label,
        gradingType: GradingTypes[gradingType].label(),
      })
    }

    return (
      <div className={classNames(topClasses)}>
        <ScreenReaderContent>
          <label className="cr-percent-input__label" htmlFor={this.shortid}>
            {srLabel}
          </label>
        </ScreenReaderContent>
        <TextInput
          className="cr-input cr-percent-input__input"
          id={this.shortid}
          type="text"
          value={this.value()}
          title={this.props.label}
          onChange={this.changed}
          onFocus={this.focused}
          onBlur={this.blurred}
          messages={this.hasError() ? [{text: this.errorMessage(), type: 'error'}] : null}
          {...optionalProps}
        />
      </div>
    )
  }
}
